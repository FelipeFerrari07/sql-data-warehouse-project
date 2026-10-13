/*
===============================================================================
Procedure: silver.load_silver
===============================================================================
Objetivo:
    Carrega a camada Silver a partir da Bronze (ETL: Bronze -> Silver).
    Para cada tabela: TRUNCATE + INSERT ... SELECT com a limpeza aplicada.
    As regras de limpeza (e as evidências que as motivaram) estão resumidas em
    docs/silver_cleaning_rules.md.

Uso:
    CALL silver.load_silver();      -- sem parâmetros: lê direto de bronze.*

Decisões:
    - A limpeza fica na Silver (e não na consulta final) para ser feita UMA vez
      e valer para todo consumidor: a Gold e qualquer análise leem dado já limpo.
    - Atomicidade: o CALL roda em uma única transação. Se algo falhar, o erro é
      registrado e relançado, e a Silver volta ao estado anterior.
    - dwh_create_date usa CURRENT_TIMESTAMP, que no PostgreSQL é o horário de
      início da transação: todas as linhas de uma mesma execução recebem o
      mesmo valor (identifica "a carga" a que pertencem).
===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    v_batch_start  TIMESTAMPTZ;
    v_start        TIMESTAMPTZ;
    v_rows         BIGINT;
BEGIN
    v_batch_start := clock_timestamp();
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Carregando a camada Silver';
    RAISE NOTICE '================================================';

    -- ======================================================================
    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Carregando tabelas do CRM';
    RAISE NOTICE '------------------------------------------------';

    -- ----------------------------------------------------------------------
    -- crm_cust_info
    --   * remove clientes sem id e mantém só o registro MAIS RECENTE de cada id
    --   * remove espaços de nomes e traduz códigos (S/M, F/M) para texto
    -- ----------------------------------------------------------------------
    v_start := clock_timestamp();
    TRUNCATE TABLE silver.crm_cust_info;
    INSERT INTO silver.crm_cust_info (
        cst_id, cst_key, cst_firstname, cst_lastname,
        cst_marital_status, cst_gndr, cst_create_date
    )
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname),
        TRIM(cst_lastname),
        CASE UPPER(TRIM(cst_marital_status))
            WHEN 'S' THEN 'Single'
            WHEN 'M' THEN 'Married'
            ELSE 'n/a'
        END,
        CASE UPPER(TRIM(cst_gndr))
            WHEN 'F' THEN 'Female'
            WHEN 'M' THEN 'Male'
            ELSE 'n/a'
        END,
        cst_create_date
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC NULLS LAST   -- NULLS LAST: no PostgreSQL, NULL vem primeiro no DESC
            ) AS flag_last
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) t
    WHERE flag_last = 1;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '>> silver.crm_cust_info: % linhas em % s',
                 v_rows, round(extract(epoch FROM clock_timestamp() - v_start)::numeric, 2);

    -- ----------------------------------------------------------------------
    -- crm_prd_info
    --   * separa a chave em cat_id (liga com o ERP) e prd_key (liga com vendas)
    --   * custo nulo vira 0; código da linha de produto vira texto
    --   * recalcula prd_end_dt = (início da próxima versão do produto) - 1 dia
    -- ----------------------------------------------------------------------
    v_start := clock_timestamp();
    TRUNCATE TABLE silver.crm_prd_info;
    INSERT INTO silver.crm_prd_info (
        prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
    )
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key FROM 1 FOR 5), '-', '_'),
        SUBSTRING(prd_key FROM 7),
        prd_nm,
        COALESCE(prd_cost, 0),
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
        END,
        prd_start_dt::DATE,
        LEAD(prd_start_dt::DATE) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1
    FROM bronze.crm_prd_info;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '>> silver.crm_prd_info: % linhas em % s',
                 v_rows, round(extract(epoch FROM clock_timestamp() - v_start)::numeric, 2);

    -- ----------------------------------------------------------------------
    -- crm_sales_details
    --   * datas: INT YYYYMMDD -> DATE; zero ou tamanho errado vira NULL
    --   * sales: se nulo, <= 0 ou diferente de quantidade x preço, recalcula
    --   * price: se nulo ou <= 0, deriva de sales / quantidade
    -- ----------------------------------------------------------------------
    v_start := clock_timestamp();
    TRUNCATE TABLE silver.crm_sales_details;
    INSERT INTO silver.crm_sales_details (
        sls_ord_num, sls_prd_key, sls_cust_id,
        sls_order_dt, sls_ship_dt, sls_due_dt,
        sls_sales, sls_quantity, sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::TEXT) <> 8
             THEN NULL ELSE TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD') END,
        CASE WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::TEXT) <> 8
             THEN NULL ELSE TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD') END,
        CASE WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::TEXT) <> 8
             THEN NULL ELSE TO_DATE(sls_due_dt::TEXT, 'YYYYMMDD') END,
        CASE WHEN sls_sales IS NULL OR sls_sales <= 0
                  OR sls_sales <> sls_quantity * ABS(sls_price)
             THEN sls_quantity * ABS(sls_price)
             ELSE sls_sales END,
        sls_quantity,
        CASE WHEN sls_price IS NULL OR sls_price <= 0
             THEN sls_sales / NULLIF(sls_quantity, 0)
             ELSE sls_price END
    FROM bronze.crm_sales_details;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '>> silver.crm_sales_details: % linhas em % s',
                 v_rows, round(extract(epoch FROM clock_timestamp() - v_start)::numeric, 2);

    -- ======================================================================
    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Carregando tabelas do ERP';
    RAISE NOTICE '------------------------------------------------';

    -- ----------------------------------------------------------------------
    -- erp_cust_az12
    --   * remove o prefixo 'NAS' do cid (para casar com cst_key do CRM)
    --   * data de nascimento no futuro vira NULL
    --   * padroniza gênero (F, FEMALE, M, MALE, vazio, nulo)
    -- ----------------------------------------------------------------------
    v_start := clock_timestamp();
    TRUNCATE TABLE silver.erp_cust_az12;
    INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
    SELECT
        CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid FROM 4) ELSE cid END,
        CASE WHEN bdate > CURRENT_DATE THEN NULL ELSE bdate END,
        CASE
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')   THEN 'Male'
            ELSE 'n/a'
        END
    FROM bronze.erp_cust_az12;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '>> silver.erp_cust_az12: % linhas em % s',
                 v_rows, round(extract(epoch FROM clock_timestamp() - v_start)::numeric, 2);

    -- ----------------------------------------------------------------------
    -- erp_loc_a101
    --   * remove o hífen do cid (AW-00011000 -> AW00011000)
    --   * padroniza países (DE, US, USA, vazio, nulo)
    -- ----------------------------------------------------------------------
    v_start := clock_timestamp();
    TRUNCATE TABLE silver.erp_loc_a101;
    INSERT INTO silver.erp_loc_a101 (cid, cntry)
    SELECT
        REPLACE(cid, '-', ''),
        CASE
            WHEN TRIM(cntry) = 'DE'               THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'USA')     THEN 'United States'
            WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'n/a'
            ELSE TRIM(cntry)
        END
    FROM bronze.erp_loc_a101;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '>> silver.erp_loc_a101: % linhas em % s',
                 v_rows, round(extract(epoch FROM clock_timestamp() - v_start)::numeric, 2);

    -- ----------------------------------------------------------------------
    -- erp_px_cat_g1v2
    --   * dado já limpo na origem: carga direta, sem transformação
    -- ----------------------------------------------------------------------
    v_start := clock_timestamp();
    TRUNCATE TABLE silver.erp_px_cat_g1v2;
    INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
    SELECT id, cat, subcat, maintenance
    FROM bronze.erp_px_cat_g1v2;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '>> silver.erp_px_cat_g1v2: % linhas em % s',
                 v_rows, round(extract(epoch FROM clock_timestamp() - v_start)::numeric, 2);

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Carga da Silver concluída em % s',
                 round(extract(epoch FROM clock_timestamp() - v_batch_start)::numeric, 2);
    RAISE NOTICE '================================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '================================================';
        RAISE NOTICE 'ERRO NA CARGA DA SILVER (tudo foi revertido)';
        RAISE NOTICE 'Mensagem: %', SQLERRM;
        RAISE NOTICE 'Código: %', SQLSTATE;
        RAISE NOTICE '================================================';
        RAISE;
END;
$$;

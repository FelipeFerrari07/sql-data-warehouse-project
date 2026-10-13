/*
===============================================================================
Procedure: bronze.load_bronze
===============================================================================
Objetivo:
    Carrega a camada Bronze a partir dos 6 CSVs de origem. Para cada tabela:
        1. TRUNCATE  -> esvazia a tabela
        2. COPY      -> carrega o CSV inteiro (full load)
    Mostra no log (aba Messages do pgAdmin) as linhas e o tempo de cada carga.

Parâmetro:
    p_base_path : pasta "datasets" do projeto, com barras normais (/), SEM barra
                  no final. Ex.: 'C:/Users/Public/datasets'
                  (o caminho é parâmetro para não ficar fixo no código: ele muda
                  de máquina para máquina)

Uso:
    CALL bronze.load_bronze('C:/Users/Public/datasets');

Decisões:
    - TRUNCATE antes de cada COPY: sem ele, rodar a carga duas vezes duplicaria
      todas as linhas (a Bronze não tem chave para barrar duplicatas).
    - Nenhuma transformação: a Bronze recebe o dado como veio da origem.
    - Atomicidade: o PostgreSQL executa o CALL inteiro em uma única transação.
      Se qualquer COPY falhar, o erro é registrado e relançado, e TUDO volta ao
      estado anterior (inclusive os TRUNCATEs). A Bronze nunca fica pela metade.
    - COPY (no servidor) lê o arquivo com o usuário do serviço do PostgreSQL. No
      Windows, o arquivo precisa estar em uma pasta que esse serviço consiga ler
      (por exemplo, C:/Users/Public). Pastas dentro do seu usuário/OneDrive
      costumam dar "permission denied".
    - Equivalente no SQL Server (vídeo): BULK INSERT ... FROM 'caminho'
      WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK).
===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze(p_base_path TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_batch_start  TIMESTAMPTZ;
    v_start        TIMESTAMPTZ;
    v_rows         BIGINT;
BEGIN
    v_batch_start := clock_timestamp();
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Carregando a camada Bronze';
    RAISE NOTICE '================================================';

    -- ------------------------------------------------------------------
    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Carregando tabelas do CRM';
    RAISE NOTICE '------------------------------------------------';

    v_start := clock_timestamp();
    TRUNCATE TABLE bronze.crm_cust_info;
    EXECUTE format('COPY bronze.crm_cust_info FROM %L WITH (FORMAT csv, HEADER true)',
                   p_base_path || '/source_crm/cust_info.csv');
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '>> bronze.crm_cust_info: % linhas em % s',
                 v_rows, round(extract(epoch FROM clock_timestamp() - v_start)::numeric, 2);

    v_start := clock_timestamp();
    TRUNCATE TABLE bronze.crm_prd_info;
    EXECUTE format('COPY bronze.crm_prd_info FROM %L WITH (FORMAT csv, HEADER true)',
                   p_base_path || '/source_crm/prd_info.csv');
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '>> bronze.crm_prd_info: % linhas em % s',
                 v_rows, round(extract(epoch FROM clock_timestamp() - v_start)::numeric, 2);

    v_start := clock_timestamp();
    TRUNCATE TABLE bronze.crm_sales_details;
    EXECUTE format('COPY bronze.crm_sales_details FROM %L WITH (FORMAT csv, HEADER true)',
                   p_base_path || '/source_crm/sales_details.csv');
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '>> bronze.crm_sales_details: % linhas em % s',
                 v_rows, round(extract(epoch FROM clock_timestamp() - v_start)::numeric, 2);

    -- ------------------------------------------------------------------
    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Carregando tabelas do ERP';
    RAISE NOTICE '------------------------------------------------';

    v_start := clock_timestamp();
    TRUNCATE TABLE bronze.erp_cust_az12;
    EXECUTE format('COPY bronze.erp_cust_az12 FROM %L WITH (FORMAT csv, HEADER true)',
                   p_base_path || '/source_erp/CUST_AZ12.csv');
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '>> bronze.erp_cust_az12: % linhas em % s',
                 v_rows, round(extract(epoch FROM clock_timestamp() - v_start)::numeric, 2);

    v_start := clock_timestamp();
    TRUNCATE TABLE bronze.erp_loc_a101;
    EXECUTE format('COPY bronze.erp_loc_a101 FROM %L WITH (FORMAT csv, HEADER true)',
                   p_base_path || '/source_erp/LOC_A101.csv');
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '>> bronze.erp_loc_a101: % linhas em % s',
                 v_rows, round(extract(epoch FROM clock_timestamp() - v_start)::numeric, 2);

    v_start := clock_timestamp();
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;
    EXECUTE format('COPY bronze.erp_px_cat_g1v2 FROM %L WITH (FORMAT csv, HEADER true)',
                   p_base_path || '/source_erp/PX_CAT_G1V2.csv');
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '>> bronze.erp_px_cat_g1v2: % linhas em % s',
                 v_rows, round(extract(epoch FROM clock_timestamp() - v_start)::numeric, 2);

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Carga da Bronze concluída em % s',
                 round(extract(epoch FROM clock_timestamp() - v_batch_start)::numeric, 2);
    RAISE NOTICE '================================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '================================================';
        RAISE NOTICE 'ERRO NA CARGA DA BRONZE (tudo foi revertido)';
        RAISE NOTICE 'Mensagem: %', SQLERRM;
        RAISE NOTICE 'Código: %', SQLSTATE;
        RAISE NOTICE '================================================';
        RAISE;   -- relança o erro: o CALL falha e a transação inteira é desfeita
END;
$$;

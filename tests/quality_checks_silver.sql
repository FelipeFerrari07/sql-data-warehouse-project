/*
===============================================================================
Checagens de qualidade - Camada Silver
===============================================================================
Objetivo:
    Confirmar que a limpeza da Silver funcionou. Cada linha é uma regra que
    estava quebrada na Bronze; a coluna "problemas" deve ser 0 e o "status" OK.
    As últimas linhas conferem a contagem de linhas e a integridade entre as
    tabelas (nenhuma venda "órfã"), pré-requisito para montar a Gold.

Como usar:
    Rode depois de CALL silver.load_silver();
===============================================================================
*/

SELECT check_name, problemas, CASE WHEN problemas = 0 THEN 'OK' ELSE 'FALHOU' END AS status
FROM (
    -- ---------------------------- crm_cust_info ----------------------------
    SELECT 'cust_info: id nulo ou duplicado' AS check_name, COUNT(*) AS problemas FROM (
        SELECT cst_id FROM silver.crm_cust_info GROUP BY cst_id HAVING COUNT(*) > 1 OR cst_id IS NULL) t
    UNION ALL
    SELECT 'cust_info: nome/sobrenome com espaço extra', COUNT(*) FROM silver.crm_cust_info
        WHERE cst_firstname <> TRIM(cst_firstname) OR cst_lastname <> TRIM(cst_lastname)
    UNION ALL
    SELECT 'cust_info: estado civil fora do padrão', COUNT(*) FROM silver.crm_cust_info
        WHERE cst_marital_status NOT IN ('Single', 'Married', 'n/a')
    UNION ALL
    SELECT 'cust_info: gênero fora do padrão', COUNT(*) FROM silver.crm_cust_info
        WHERE cst_gndr NOT IN ('Male', 'Female', 'n/a')

    -- ---------------------------- crm_prd_info -----------------------------
    UNION ALL
    SELECT 'prd_info: data final antes da inicial', COUNT(*) FROM silver.crm_prd_info
        WHERE prd_end_dt < prd_start_dt
    UNION ALL
    SELECT 'prd_info: custo nulo', COUNT(*) FROM silver.crm_prd_info WHERE prd_cost IS NULL
    UNION ALL
    SELECT 'prd_info: linha de produto fora do padrão', COUNT(*) FROM silver.crm_prd_info
        WHERE prd_line NOT IN ('Mountain', 'Road', 'Other Sales', 'Touring', 'n/a')

    -- -------------------------- crm_sales_details --------------------------
    UNION ALL
    SELECT 'sales: datas fora de ordem (pedido > envio ou envio > vencimento)', COUNT(*) FROM silver.crm_sales_details
        WHERE sls_order_dt > sls_ship_dt OR sls_ship_dt > sls_due_dt
    UNION ALL
    SELECT 'sales: valor, preço ou quantidade nulos/não positivos', COUNT(*) FROM silver.crm_sales_details
        WHERE sls_sales IS NULL OR sls_sales <= 0 OR sls_price IS NULL OR sls_price <= 0
           OR sls_quantity IS NULL OR sls_quantity <= 0
    UNION ALL
    SELECT 'sales: valor diferente de quantidade x preço', COUNT(*) FROM silver.crm_sales_details
        WHERE sls_sales <> sls_quantity * sls_price

    -- ---------------------------- erp_cust_az12 ----------------------------
    UNION ALL
    SELECT 'az12: nascimento no futuro', COUNT(*) FROM silver.erp_cust_az12 WHERE bdate > CURRENT_DATE
    UNION ALL
    SELECT 'az12: gênero fora do padrão', COUNT(*) FROM silver.erp_cust_az12
        WHERE gen NOT IN ('Male', 'Female', 'n/a')
    UNION ALL
    SELECT 'az12: cid ainda com prefixo NAS', COUNT(*) FROM silver.erp_cust_az12 WHERE cid LIKE 'NAS%'

    -- ----------------------------- erp_loc_a101 ----------------------------
    UNION ALL
    SELECT 'loc: cid ainda com hífen', COUNT(*) FROM silver.erp_loc_a101 WHERE cid LIKE '%-%'
    UNION ALL
    SELECT 'loc: país abreviado, vazio ou nulo', COUNT(*) FROM silver.erp_loc_a101
        WHERE cntry IS NULL OR TRIM(cntry) = '' OR cntry IN ('DE', 'US', 'USA')

    -- ------------------- contagem de linhas (esperado) ---------------------
    UNION ALL SELECT 'linhas: crm_cust_info (esperado 18484)',     ABS(COUNT(*) - 18484) FROM silver.crm_cust_info
    UNION ALL SELECT 'linhas: crm_prd_info (esperado 397)',        ABS(COUNT(*) - 397)   FROM silver.crm_prd_info
    UNION ALL SELECT 'linhas: crm_sales_details (esperado 60398)', ABS(COUNT(*) - 60398) FROM silver.crm_sales_details
    UNION ALL SELECT 'linhas: erp_cust_az12 (esperado 18484)',     ABS(COUNT(*) - 18484) FROM silver.erp_cust_az12
    UNION ALL SELECT 'linhas: erp_loc_a101 (esperado 18484)',      ABS(COUNT(*) - 18484) FROM silver.erp_loc_a101
    UNION ALL SELECT 'linhas: erp_px_cat_g1v2 (esperado 37)',      ABS(COUNT(*) - 37)    FROM silver.erp_px_cat_g1v2

    -- ------------- integridade entre tabelas (pré-requisito da Gold) -------
    UNION ALL
    SELECT 'integridade: vendas sem cliente', COUNT(*) FROM silver.crm_sales_details s
        WHERE NOT EXISTS (SELECT 1 FROM silver.crm_cust_info c WHERE c.cst_id = s.sls_cust_id)
    UNION ALL
    SELECT 'integridade: vendas sem produto', COUNT(*) FROM silver.crm_sales_details s
        WHERE NOT EXISTS (SELECT 1 FROM silver.crm_prd_info p WHERE p.prd_key = s.sls_prd_key)
    UNION ALL
    SELECT 'integridade: cid do ERP sem cliente no CRM (az12)', COUNT(*) FROM silver.erp_cust_az12 e
        WHERE NOT EXISTS (SELECT 1 FROM silver.crm_cust_info c WHERE c.cst_key = e.cid)
    UNION ALL
    SELECT 'integridade: cid do ERP sem cliente no CRM (loc)', COUNT(*) FROM silver.erp_loc_a101 l
        WHERE NOT EXISTS (SELECT 1 FROM silver.crm_cust_info c WHERE c.cst_key = l.cid)
) checks
ORDER BY status DESC, check_name;

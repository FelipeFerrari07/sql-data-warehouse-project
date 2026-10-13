/*
===============================================================================
Checagens de qualidade - Camada Bronze
===============================================================================
Objetivo:
    Confirmar que a carga da Bronze funcionou, comparando o número de linhas
    de cada tabela com o número de linhas de dados do CSV (sem o cabeçalho).

Como usar:
    Rode depois de CALL bronze.load_bronze(...). A coluna "status" deve ser OK
    em todas as linhas. Qualquer DIVERGENTE indica carga incompleta ou duplicada.

Como conferir o esperado no Windows (PowerShell), por exemplo:
    (Get-Content .\datasets\source_crm\cust_info.csv | Measure-Object -Line).Lines - 1
===============================================================================
*/

WITH contagem AS (
    SELECT 'bronze.crm_cust_info'     AS tabela, 18494 AS esperado, COUNT(*) AS carregado FROM bronze.crm_cust_info
    UNION ALL
    SELECT 'bronze.crm_prd_info',                   397,            COUNT(*) FROM bronze.crm_prd_info
    UNION ALL
    SELECT 'bronze.crm_sales_details',              60398,          COUNT(*) FROM bronze.crm_sales_details
    UNION ALL
    SELECT 'bronze.erp_cust_az12',                  18484,          COUNT(*) FROM bronze.erp_cust_az12
    UNION ALL
    SELECT 'bronze.erp_loc_a101',                   18484,          COUNT(*) FROM bronze.erp_loc_a101
    UNION ALL
    SELECT 'bronze.erp_px_cat_g1v2',                37,             COUNT(*) FROM bronze.erp_px_cat_g1v2
)
SELECT
    tabela,
    esperado,
    carregado,
    CASE WHEN esperado = carregado THEN 'OK' ELSE 'DIVERGENTE' END AS status
FROM contagem
ORDER BY tabela;

-- Checagem 2: a Bronze NÃO pode ter tratado nada. Estes espaços extras e
-- gêneros em branco ainda devem existir (a limpeza é papel da Silver).
SELECT
    COUNT(*) FILTER (WHERE cst_firstname <> TRIM(cst_firstname)) AS nomes_com_espaco_extra,
    COUNT(*) FILTER (WHERE cst_gndr IS NULL)                      AS generos_nulos,
    COUNT(*) FILTER (WHERE cst_id IS NULL)                        AS ids_nulos
FROM bronze.crm_cust_info;

/*
===============================================================================
Checagens de qualidade - Camada Gold
===============================================================================
Objetivo:
    Confirmar que o modelo estrela está íntegro: chaves únicas, nenhuma venda
    "sem dono" (sem cliente ou produto) e nenhuma linha perdida ou multiplicada
    pelos JOINs. Cada linha deve ter problemas = 0 e status OK.

Como usar:
    Rode depois de criar as views (scripts/gold/ddl_gold.sql).
===============================================================================
*/

SELECT check_name, problemas, CASE WHEN problemas = 0 THEN 'OK' ELSE 'FALHOU' END AS status
FROM (
    -- ------------------------- chaves únicas nas dimensões -------------------------
    SELECT 'dim_customers: customer_key duplicada' AS check_name, COUNT(*) AS problemas FROM (
        SELECT customer_key FROM gold.dim_customers GROUP BY customer_key HAVING COUNT(*) > 1) t
    UNION ALL
    SELECT 'dim_customers: customer_id duplicado', COUNT(*) FROM (
        SELECT customer_id FROM gold.dim_customers GROUP BY customer_id HAVING COUNT(*) > 1) t
    UNION ALL
    SELECT 'dim_products: product_key duplicada', COUNT(*) FROM (
        SELECT product_key FROM gold.dim_products GROUP BY product_key HAVING COUNT(*) > 1) t
    UNION ALL
    SELECT 'dim_products: product_number duplicado (mais de uma versão atual)', COUNT(*) FROM (
        SELECT product_number FROM gold.dim_products GROUP BY product_number HAVING COUNT(*) > 1) t

    -- ------------------- integridade referencial do fato -------------------------
    UNION ALL
    SELECT 'fact_sales: venda sem cliente (customer_key nula)', COUNT(*) FROM gold.fact_sales WHERE customer_key IS NULL
    UNION ALL
    SELECT 'fact_sales: venda sem produto (product_key nula)', COUNT(*) FROM gold.fact_sales WHERE product_key IS NULL

    -- ------- nenhum JOIN perdeu ou multiplicou linhas (Gold x Silver) ------------
    UNION ALL
    SELECT 'fact_sales: diferença de linhas vs silver', ABS(
        (SELECT COUNT(*) FROM gold.fact_sales) - (SELECT COUNT(*) FROM silver.crm_sales_details))
    UNION ALL
    SELECT 'dim_customers: diferença de linhas vs silver', ABS(
        (SELECT COUNT(*) FROM gold.dim_customers) - (SELECT COUNT(*) FROM silver.crm_cust_info))
    UNION ALL
    SELECT 'dim_products: diferença vs versões atuais da silver', ABS(
        (SELECT COUNT(*) FROM gold.dim_products) - (SELECT COUNT(*) FROM silver.crm_prd_info WHERE prd_end_dt IS NULL))

    -- ------------------------ conciliação de valores -----------------------------
    UNION ALL
    SELECT 'fact_sales: receita total difere da silver',
        ABS((SELECT SUM(sales_amount) FROM gold.fact_sales) - (SELECT SUM(sls_sales) FROM silver.crm_sales_details))

    -- ------------------------ regras de conteúdo ---------------------------------
    UNION ALL
    SELECT 'dim_customers: gênero nulo ou fora do padrão', COUNT(*) FROM gold.dim_customers
        WHERE gender IS NULL OR gender NOT IN ('Male', 'Female', 'n/a')
    UNION ALL
    SELECT 'dim_products: produto sem categoria (exceto CO_PE, ausente no ERP)', COUNT(*) FROM gold.dim_products
        WHERE category IS NULL AND category_id <> 'CO_PE'
) checks
ORDER BY status DESC, check_name;

/*
===============================================================================
DDL - Camada Gold (modelo estrela)
===============================================================================
Objetivo:
    Cria as 3 views da camada Gold:
        gold.dim_customers  (dimensão: quem comprou)
        gold.dim_products   (dimensão: o que foi comprado)
        gold.fact_sales     (fato: uma linha por item vendido)
    Elas integram CRM e ERP lendo direto da Silver. O resultado é um modelo
    estrela pronto para consulta e BI.

Como executar:
    Conectado no banco "data_warehouse", com a Silver já carregada
    (CALL silver.load_silver()), execute este arquivo na Query Tool.

Decisões:
    - VIEW e não tabela: a Gold não guarda dado, só a "receita" da consulta.
      Sempre reflete a Silver atual, sem um passo de carga extra nem dado
      duplicado. Custo: a consulta é recalculada a cada uso (JOINs e funções
      de janela), o que pesa mais em bases grandes.
    - Chave substituta (surrogate key): customer_key e product_key são números
      sequenciais criados aqui (ROW_NUMBER), independentes do código do sistema
      de origem. O fato se liga às dimensões por essas chaves.
      Atenção: como são geradas na consulta, só permanecem estáveis enquanto os
      dados da Silver não mudarem. Em produção seriam gravadas em tabela.
    - Dois sistemas descrevem o cliente (CRM e ERP): o CRM prevalece; o ERP só
      preenche o gênero quando o CRM está 'n/a'.
    - Só a versão ATUAL de cada produto entra na dim_products (prd_end_dt IS
      NULL), porque o escopo do projeto não inclui historização.
    - Os JOINs são LEFT: nenhuma linha do lado principal some se faltar o
      cadastro correspondente (ex.: categoria CO_PE não existe no ERP).
    - As views são apagadas na ordem inversa da dependência (fato primeiro).
===============================================================================
*/

DROP VIEW IF EXISTS gold.fact_sales;
DROP VIEW IF EXISTS gold.dim_products;
DROP VIEW IF EXISTS gold.dim_customers;

-- ============================================================================
-- Dimensão: clientes
-- ============================================================================
CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id)  AS customer_key,
    ci.cst_id                               AS customer_id,
    ci.cst_key                              AS customer_number,
    ci.cst_firstname                        AS first_name,
    ci.cst_lastname                         AS last_name,
    la.cntry                                AS country,
    ci.cst_marital_status                   AS marital_status,
    CASE
        WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr          -- CRM prevalece
        ELSE COALESCE(ca.gen, 'n/a')                         -- ERP só preenche lacunas
    END                                     AS gender,
    ca.bdate                                AS birthdate,
    ci.cst_create_date                      AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  la ON ci.cst_key = la.cid;

-- ============================================================================
-- Dimensão: produtos
-- ============================================================================
CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
    pn.prd_id        AS product_id,
    pn.prd_key       AS product_number,
    pn.prd_nm        AS product_name,
    pn.cat_id        AS category_id,
    pc.cat           AS category,
    pc.subcat        AS subcategory,
    pc.maintenance   AS maintenance,
    pn.prd_cost      AS cost,
    pn.prd_line      AS product_line,
    pn.prd_start_dt  AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;     -- só a versão atual do produto (sem historização)

-- ============================================================================
-- Fato: vendas
-- ============================================================================
CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num   AS order_number,
    pr.product_key   AS product_key,
    cu.customer_key  AS customer_key,
    sd.sls_order_dt  AS order_date,
    sd.sls_ship_dt   AS shipping_date,
    sd.sls_due_dt    AS due_date,
    sd.sls_sales     AS sales_amount,
    sd.sls_quantity  AS quantity,
    sd.sls_price     AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products  pr ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu ON sd.sls_cust_id = cu.customer_id;

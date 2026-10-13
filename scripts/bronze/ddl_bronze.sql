/*
===============================================================================
DDL - Camada Bronze
===============================================================================
Objetivo:
    Cria as 6 tabelas da camada Bronze, uma para cada CSV de origem.
    Se a tabela já existir, ela é apagada e recriada (DROP ... IF EXISTS).

Como executar:
    Conectado no banco "data_warehouse", execute este arquivo na Query Tool.

Decisões:
    - Os nomes seguem o padrão <sistema>_<entidade> (crm_*, erp_*), igual ao
      arquivo de origem, sem renomear nada (ver docs/naming_conventions.md).
    - A Bronze guarda o dado BRUTO: nenhuma regra de negócio, nenhuma limpeza.
      Por isso as datas de vendas ficam como INT (20101229), como vieram.
      A conversão para DATE é trabalho da Silver.
    - Os tipos vieram do perfil dos CSVs: textos cabem em VARCHAR(50),
      custos/valores/quantidades são inteiros.
===============================================================================
*/

-- ----------------------------------------------------------------------------
-- CRM
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info (
    cst_id              INT,
    cst_key             VARCHAR(50),
    cst_firstname       VARCHAR(50),
    cst_lastname        VARCHAR(50),
    cst_marital_status  VARCHAR(50),
    cst_gndr            VARCHAR(50),
    cst_create_date     DATE
);

DROP TABLE IF EXISTS bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info (
    prd_id        INT,
    prd_key       VARCHAR(50),
    prd_nm        VARCHAR(50),
    prd_cost      INT,
    prd_line      VARCHAR(50),
    prd_start_dt  TIMESTAMP,
    prd_end_dt    TIMESTAMP
);

DROP TABLE IF EXISTS bronze.crm_sales_details;
CREATE TABLE bronze.crm_sales_details (
    sls_ord_num   VARCHAR(50),
    sls_prd_key   VARCHAR(50),
    sls_cust_id   INT,
    sls_order_dt  INT,   -- formato YYYYMMDD, como veio da origem
    sls_ship_dt   INT,
    sls_due_dt    INT,
    sls_sales     INT,
    sls_quantity  INT,
    sls_price     INT
);

-- ----------------------------------------------------------------------------
-- ERP
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS bronze.erp_cust_az12;
CREATE TABLE bronze.erp_cust_az12 (
    cid    VARCHAR(50),
    bdate  DATE,
    gen    VARCHAR(50)
);

DROP TABLE IF EXISTS bronze.erp_loc_a101;
CREATE TABLE bronze.erp_loc_a101 (
    cid    VARCHAR(50),
    cntry  VARCHAR(50)
);

DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;
CREATE TABLE bronze.erp_px_cat_g1v2 (
    id           VARCHAR(50),
    cat          VARCHAR(50),
    subcat       VARCHAR(50),
    maintenance  VARCHAR(50)
);

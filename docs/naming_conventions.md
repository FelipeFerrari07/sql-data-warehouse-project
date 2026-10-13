# Convenções de nomes

Padrões adotados em todo o projeto, para manter o código consistente.

## Regras gerais
- Formato **snake_case**: letras minúsculas, palavras separadas por `_`.
- Nomes em **inglês**.
- Evitar palavras reservadas do SQL como nome de objeto.

## Schemas e banco
- Banco de dados: `data_warehouse`
- Um schema por camada: `bronze`, `silver`, `gold`.

## Tabelas
### Bronze e Silver — `<sistema>_<entidade>`
Mantêm o nome do sistema de origem e da entidade, sem renomear.
- `crm_cust_info` → sistema `crm`, entidade `cust_info`
- `erp_loc_a101` → sistema `erp`, entidade `loc_a101`

### Gold — `<categoria>_<entidade>`
Nomes orientados ao negócio, com prefixo que indica o papel da tabela.
- `dim_` para dimensões → `gold.dim_customers`, `gold.dim_products`
- `fact_` para fatos → `gold.fact_sales`

## Colunas
- **Chaves substitutas (surrogate keys):** `<entidade>_key` → `customer_key`, `product_key`
- **Colunas técnicas / metadados:** prefixo `dwh_` → `dwh_create_date` (data/hora em que a linha foi carregada na Silver)

## Procedures de carga
- `load_<camada>` → `bronze.load_bronze`, `silver.load_silver`

## Arquivos de script
- Numerados na ordem de execução e com nome descritivo: `00_create_database.sql`, `01_create_schemas.sql`, ...

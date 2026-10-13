# Catálogo de dados — camada Gold

## gold.dim_customers
Dimensão de clientes: integra o cadastro do CRM com nascimento/gênero e país do ERP.
| Coluna | Tipo | Descrição |
|---|---|---|
| customer_key | INT | Chave substituta (sequencial) do cliente na dimensão |
| customer_id | INT | Identificador do cliente no CRM |
| customer_number | VARCHAR | Código alfanumérico do cliente (ex.: `AW00011000`); liga CRM e ERP |
| first_name | VARCHAR | Nome |
| last_name | VARCHAR | Sobrenome |
| country | VARCHAR | País do cliente (ERP); `n/a` quando desconhecido |
| marital_status | VARCHAR | `Single`, `Married` ou `n/a` |
| gender | VARCHAR | `Male`, `Female` ou `n/a`. CRM prevalece; o ERP preenche quando o CRM é `n/a` |
| birthdate | DATE | Data de nascimento (ERP); `NULL` quando ausente ou inválida |
| create_date | DATE | Data de cadastro no CRM |

## gold.dim_products
Dimensão de produtos: apenas a **versão atual** de cada produto, com a categoria vinda do ERP.
| Coluna | Tipo | Descrição |
|---|---|---|
| product_key | INT | Chave substituta (sequencial) do produto |
| product_id | INT | Identificador da versão do produto no CRM |
| product_number | VARCHAR | Código do produto (ex.: `BK-M82B-38`); liga com as vendas |
| product_name | VARCHAR | Nome do produto |
| category_id | VARCHAR | Código da categoria (ex.: `BI_MB`) |
| category | VARCHAR | Categoria (ex.: `Bikes`) |
| subcategory | VARCHAR | Subcategoria (ex.: `Mountain Bikes`) |
| maintenance | VARCHAR | Se exige manutenção: `Yes` ou `No` |
| cost | INT | Custo do produto (0 quando desconhecido) |
| product_line | VARCHAR | `Road`, `Mountain`, `Touring`, `Other Sales` ou `n/a` |
| start_date | DATE | Início de vigência da versão atual |

## gold.fact_sales
Fato de vendas: uma linha por item vendido.
| Coluna | Tipo | Descrição |
|---|---|---|
| order_number | VARCHAR | Número do pedido (ex.: `SO43697`) |
| product_key | INT | Chave do produto (FK para `dim_products`) |
| customer_key | INT | Chave do cliente (FK para `dim_customers`) |
| order_date | DATE | Data do pedido; `NULL` em 19 casos de data inválida na origem |
| shipping_date | DATE | Data de envio |
| due_date | DATE | Data de vencimento |
| sales_amount | INT | Valor total da linha (= quantidade × preço) |
| quantity | INT | Quantidade de unidades |
| price | INT | Preço unitário |

# Fluxo de dados (data flow)

Atualizado a cada camada concluída.

## Bronze — origem → tabelas brutas

```mermaid
flowchart LR
    subgraph CRM["Sistema CRM"]
        A1["cust_info.csv"]
        A2["prd_info.csv"]
        A3["sales_details.csv"]
    end
    subgraph ERP["Sistema ERP"]
        B1["CUST_AZ12.csv"]
        B2["LOC_A101.csv"]
        B3["PX_CAT_G1V2.csv"]
    end
    subgraph BRONZE["Schema bronze (via bronze.load_bronze)"]
        T1["crm_cust_info"]
        T2["crm_prd_info"]
        T3["crm_sales_details"]
        T4["erp_cust_az12"]
        T5["erp_loc_a101"]
        T6["erp_px_cat_g1v2"]
    end
    A1 --> T1
    A2 --> T2
    A3 --> T3
    B1 --> T4
    B2 --> T5
    B3 --> T6
```

Cada CSV vira exatamente uma tabela, sem transformação (relação 1:1).

## Silver — Bronze → tabelas limpas

```mermaid
flowchart LR
    subgraph BRONZE["Schema bronze"]
        B1["crm_cust_info"]
        B2["crm_prd_info"]
        B3["crm_sales_details"]
        B4["erp_cust_az12"]
        B5["erp_loc_a101"]
        B6["erp_px_cat_g1v2"]
    end
    subgraph SILVER["Schema silver (via silver.load_silver)"]
        S1["crm_cust_info"]
        S2["crm_prd_info"]
        S3["crm_sales_details"]
        S4["erp_cust_az12"]
        S5["erp_loc_a101"]
        S6["erp_px_cat_g1v2"]
    end
    B1 -->|"remove duplicatas e nulos, padroniza textos"| S1
    B2 -->|"separa chave, recalcula datas finais"| S2
    B3 -->|"converte datas, corrige valores"| S3
    B4 -->|"remove prefixo NAS, trata datas e gênero"| S4
    B5 -->|"remove hífen, padroniza países"| S5
    B6 -->|"carga direta"| S6
```

Regras detalhadas, com as evidências: [`silver_cleaning_rules.md`](silver_cleaning_rules.md).

## Gold — Silver → modelo estrela (views)

```mermaid
flowchart LR
    subgraph SILVER["Schema silver"]
        S1["crm_cust_info"]
        S4["erp_cust_az12"]
        S5["erp_loc_a101"]
        S2["crm_prd_info"]
        S6["erp_px_cat_g1v2"]
        S3["crm_sales_details"]
    end
    subgraph GOLD["Schema gold (views)"]
        D1["dim_customers"]
        D2["dim_products"]
        F["fact_sales"]
    end
    S1 -->|"base"| D1
    S4 -->|"cst_key = cid (nascimento, gênero)"| D1
    S5 -->|"cst_key = cid (país)"| D1
    S2 -->|"base (só versão atual)"| D2
    S6 -->|"cat_id = id (categoria)"| D2
    S3 -->|"base"| F
    D2 -->|"prd_key = product_number"| F
    D1 -->|"cst_id = customer_id"| F
```

Modelo resultante: [`data_model.md`](data_model.md). Dicionário de colunas: [`data_catalog.md`](data_catalog.md).
Validação contra o resultado oficial do projeto: [`validation_against_reference.md`](validation_against_reference.md).

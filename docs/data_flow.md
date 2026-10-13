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

## Silver
_A documentar quando a camada for construída._

## Gold
_A documentar quando a camada for construída._

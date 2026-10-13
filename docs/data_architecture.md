# Arquitetura de dados — Medalhão (Bronze → Silver → Gold)

```mermaid
flowchart LR
    subgraph Fontes
        CRM[/"CRM - 3 CSVs"/]
        ERP[/"ERP - 3 CSVs"/]
    end

    subgraph DW["Banco: data_warehouse"]
        B[("bronze<br/>dados brutos")]
        S[("silver<br/>dados limpos")]
        G[("gold<br/>modelo estrela")]
    end

    CRM -->|"Extract: carga em lote"| B
    ERP -->|"Extract: carga em lote"| B
    B -->|"Transform: limpeza e padronização"| S
    S -->|"Load: integração e modelagem"| G
    G --> C["Consumo: BI, consultas SQL e análises"]
```

## O que cada camada guarda

| Camada | Schema | Objetivo | Tipo de objeto | Transformação |
|---|---|---|---|---|
| Bronze | `bronze` | Guardar os dados exatamente como vieram da origem (rastreabilidade) | Tabelas | Nenhuma (carga bruta) |
| Silver | `silver` | Dados limpos e padronizados, ainda no formato das origens | Tabelas | Limpeza, padronização, tratamento de nulos e datas, remoção de duplicatas |
| Gold | `gold` | Modelo analítico pronto para o negócio | Views | Integração entre CRM e ERP, regras de negócio, modelo estrela (dimensões + fato) |

## Estratégia de carga
- **Bronze:** carga completa (*full load*) — `TRUNCATE` + `COPY` a partir dos CSVs.
- **Silver:** carga completa a partir da Bronze, via procedure.
- **Gold:** sem carga; as views leem direto da Silver.

## Fontes de dados
| Sistema | Arquivo | Conteúdo |
|---|---|---|
| CRM | `cust_info.csv` | Cadastro de clientes |
| CRM | `prd_info.csv` | Cadastro de produtos |
| CRM | `sales_details.csv` | Itens de vendas (transações) |
| ERP | `CUST_AZ12.csv` | Data de nascimento e gênero dos clientes |
| ERP | `LOC_A101.csv` | País dos clientes |
| ERP | `PX_CAT_G1V2.csv` | Categorias e subcategorias de produtos |

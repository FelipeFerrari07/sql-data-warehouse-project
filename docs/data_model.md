# Modelo de dados da Gold (esquema estrela)

```mermaid
erDiagram
    dim_customers ||--o{ fact_sales : "customer_key"
    dim_products  ||--o{ fact_sales : "product_key"

    dim_customers {
        int customer_key PK
        int customer_id
        varchar customer_number
        varchar first_name
        varchar last_name
        varchar country
        varchar marital_status
        varchar gender
        date birthdate
        date create_date
    }
    dim_products {
        int product_key PK
        int product_id
        varchar product_number
        varchar product_name
        varchar category_id
        varchar category
        varchar subcategory
        varchar maintenance
        int cost
        varchar product_line
        date start_date
    }
    fact_sales {
        varchar order_number
        int product_key FK
        int customer_key FK
        date order_date
        date shipping_date
        date due_date
        int sales_amount
        int quantity
        int price
    }
```

- **Granularidade do fato:** uma linha por item vendido (um pedido com 3 produtos gera 3 linhas).
- **Por que estrela:** poucas junções (o fato liga direto a cada dimensão), consultas simples e rápidas
  para análise, e dimensões fáceis de entender pelo negócio. Uma tabela única gigante repetiria os dados do
  cliente e do produto em cada venda.
- **Chaves substitutas:** `customer_key` e `product_key` são geradas com `ROW_NUMBER()` dentro da view; servem para
  desacoplar o modelo dos códigos dos sistemas de origem, mas só são estáveis enquanto a Silver não muda.

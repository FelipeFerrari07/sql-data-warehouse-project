# Validação da Gold contra a referência oficial

O projeto original (vídeo) publica o resultado da sua Gold em CSV (`gold.dim_customers.csv`, `gold.dim_products.csv`,
`gold.fact_sales.csv`). Carreguei esses arquivos em um schema temporário e comparei linha a linha com as views
(`EXCEPT` nos dois sentidos).

| Tabela | Resultado |
|---|---|
| `fact_sales` (60.398 linhas) | **Idêntica**, inclusive as chaves substitutas |
| `dim_products` (295 linhas) | **Idêntica** |
| `dim_customers` (18.484 linhas) | Igual em todas as colunas, exceto 2 diferenças explicadas abaixo |

Diferenças em `dim_customers` — nenhuma é erro do pipeline:
1. **93 clientes com acento diferente em nome/sobrenome.** A referência tem texto corrompido (`Andr├®s`, `Jim├®nez`:
   UTF-8 lido como CP850); este projeto preserva o acento correto (`Andrés`, `Jiménez`). Conferi que as 93 se explicam
   só por isso.
2. **1 cliente (`AW00029483`) com data de nascimento preenchida aqui e `NULL` na referência.** É a última linha do
   `CUST_AZ12.csv`, e o arquivo termina sem quebra de linha. Provável causa: a carga original (SQL Server) perdeu essa
   linha; o `COPY` do PostgreSQL a carregou normalmente.

O `EXCEPT` é uma comparação de conjuntos: aponta qualquer linha presente em só um dos lados.

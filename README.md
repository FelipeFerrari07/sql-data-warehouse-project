# SQL Data Warehouse — Arquitetura Medalhão

Projeto da Capacitação 03 (SQL para Data Warehouse) do Núcleo de Dados da EESC Jr.
Constrói um Data Warehouse em **PostgreSQL** que consolida dados de vendas de dois sistemas
(CRM e ERP) seguindo a **arquitetura medalhão** (Bronze → Silver → Gold).

Baseado no projeto "SQL Data Warehouse from Scratch" (Data With Baraa), adaptado de SQL Server para PostgreSQL.

## Arquitetura
Veja o diagrama e a descrição completa em [`docs/data_architecture.md`](docs/data_architecture.md).

| Camada | Função |
|---|---|
| Bronze | Dados brutos, exatamente como vieram dos CSVs |
| Silver | Dados limpos e padronizados |
| Gold | Modelo estrela (dimensões + fato) pronto para análise |

## Estrutura do repositório
```
├── datasets/            # CSVs de origem (source_crm e source_erp)
├── docs/                # requisitos, arquitetura e convenções de nomes
├── scripts/
│   ├── init/            # criação do banco e dos schemas
│   ├── bronze/          # DDL e carga da camada Bronze
│   ├── silver/          # DDL, limpeza e carga da camada Silver
│   └── gold/            # views do modelo estrela
├── tests/               # checagens de qualidade
└── README.md
```

## Como executar (PostgreSQL + pgAdmin 4)
1. Conectado no banco `postgres`, execute `scripts/init/00_create_database.sql`.
2. Conectado no banco `data_warehouse`, execute `scripts/init/01_create_schemas.sql`.
3. **Bronze:** execute `scripts/bronze/ddl_bronze.sql` (cria as 6 tabelas).
4. Copie a pasta `datasets/` para um local que o serviço do PostgreSQL consiga ler (ex.: `C:/Users/Public/datasets`) e carregue:
   ```sql
   CALL bronze.load_bronze('C:/Users/Public/datasets');   -- depois de criar a procedure (scripts/bronze/proc_load_bronze.sql)
   ```
5. Valide a carga com `tests/quality_checks_bronze.sql` (todas as linhas devem retornar `OK`).
6. **Silver:** execute `scripts/silver/ddl_silver.sql` e `scripts/silver/proc_load_silver.sql`, depois:
   ```sql
   CALL silver.load_silver();
   ```
   Valide com `tests/quality_checks_silver.sql` (todas as linhas devem retornar `OK`).
7. Gold: em desenvolvimento.

## Documentação
- [Análise de requisitos](docs/requirements.md)
- [Arquitetura de dados](docs/data_architecture.md)
- [Convenções de nomes](docs/naming_conventions.md)
- [Regras de limpeza da Silver](docs/silver_cleaning_rules.md)
- [Fluxo de dados](docs/data_flow.md)

## Status
- [x] Requisitos, arquitetura e convenções de nomes
- [x] Repositório organizado
- [x] Banco de dados e schemas criados
- [x] Camada Bronze (DDL, procedure de carga e checagens)
- [x] Camada Silver (DDL, procedure de limpeza e checagens)
- [ ] Camada Gold
- [ ] README final (fontes de dados, função de cada camada e tabelas da Gold)

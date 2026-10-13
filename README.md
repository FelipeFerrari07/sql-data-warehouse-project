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
3. Camadas Bronze, Silver e Gold: ver as pastas correspondentes em `scripts/` (em desenvolvimento).

## Documentação
- [Análise de requisitos](docs/requirements.md)
- [Arquitetura de dados](docs/data_architecture.md)
- [Convenções de nomes](docs/naming_conventions.md)

## Status
- [x] Requisitos, arquitetura e convenções de nomes
- [x] Repositório organizado
- [x] Banco de dados e schemas criados
- [ ] Camada Bronze
- [ ] Camada Silver
- [ ] Camada Gold
- [ ] README final (fontes de dados, função de cada camada e tabelas da Gold)

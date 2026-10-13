# Análise de requisitos

## Objetivo
Construir um Data Warehouse em SQL (PostgreSQL) que consolide dados de vendas vindos de dois
sistemas de origem (CRM e ERP), permitindo análises e relatórios a partir de um único modelo.

## Especificações
| Item | Descrição |
|---|---|
| Fontes de dados | Dois sistemas de origem, entregues como arquivos CSV: **CRM** (clientes, produtos, vendas) e **ERP** (dados complementares de clientes, localização e categorias de produtos) |
| Qualidade dos dados | Identificar e corrigir problemas de qualidade (duplicatas, espaços extras, códigos abreviados, datas inválidas, valores inconsistentes) antes de qualquer análise |
| Integração | Combinar CRM e ERP em um único modelo de dados, pensado para consultas analíticas |
| Escopo | Apenas o conjunto de dados mais recente; **não** há historização (sem versionamento de mudanças ao longo do tempo) |
| Documentação | Documentar o modelo de dados para equipes de negócio e de análise |

## Perguntas que o resultado final precisa permitir responder
Vendas por cliente, por produto e por período; perfil dos clientes (país, gênero, estado civil);
e desempenho por categoria de produto.

# Silver — problemas encontrados e regras de limpeza

Cada regra nasceu de um problema medido na Bronze (consultas exploratórias antes de escrever a limpeza).
A implementação está em `scripts/silver/proc_load_silver.sql`; a validação, em `tests/quality_checks_silver.sql`.

## crm_cust_info
| Problema encontrado | Regra aplicada |
|---|---|
| 4 linhas sem `cst_id` | Descartadas: sem chave não há como ligar o cliente às vendas |
| 5 ids duplicados (6 linhas extras) | Mantém só o registro de **maior `cst_create_date`** por id (`ROW_NUMBER`). Nos casos vistos, o mais recente é também o mais completo |
| 17 nomes e 22 sobrenomes com espaços extras | `TRIM` |
| Estado civil como código (`S`, `M`) e 7 nulos | `Single` / `Married` / `n/a` |
| Gênero como código (`F`, `M`) e 4.578 nulos | `Female` / `Male` / `n/a` |

## crm_prd_info
| Problema encontrado | Regra aplicada |
|---|---|
| `prd_key` junta categoria + produto (ex.: `CO-RF-FR-R92B-58`) | Separa em `cat_id` (5 primeiros caracteres, `-` → `_`, liga com o ERP) e `prd_key` (resto, liga com as vendas) |
| 2 custos nulos | `COALESCE(prd_cost, 0)` |
| `prd_line` como código com espaço (`R `, `M `...) e 17 nulos | `Road` / `Mountain` / `Other Sales` / `Touring` / `n/a` |
| 200 de 397 produtos com data final **anterior** à inicial | `prd_end_dt` recalculada = início da próxima versão do mesmo produto − 1 dia (`LEAD`); a versão atual fica sem data final |

## crm_sales_details
| Problema encontrado | Regra aplicada |
|---|---|
| Datas como inteiro `YYYYMMDD`; 17 datas de pedido = `0` e 2 com tamanho errado (`5489`, `32154`) | Converte para `DATE`; zero ou tamanho ≠ 8 vira `NULL` (a linha **não** é apagada: a venda continua valendo para receita e quantidade) |
| 23 vendas com `sls_sales` nulo, ≤ 0 ou ≠ quantidade × preço | Recalcula `sls_sales = quantidade × ABS(preço)` |
| 12 preços nulos ou ≤ 0 | `sls_price = sls_sales ÷ quantidade` |
| Vendas sem produto ou sem cliente no cadastro | Nenhuma encontrada (0 órfãs) |

## erp_cust_az12
| Problema encontrado | Regra aplicada |
|---|---|
| 11.042 de 18.484 ids com prefixo `NAS` (não casam com `cst_key` do CRM) | Remove o prefixo; depois disso 100% casam |
| 16 datas de nascimento no futuro (até o ano 9999) | Viram `NULL`. Os 15 nascimentos anteriores a 1924 foram mantidos |
| Gênero: `F`, `M`, `Female`, `Male`, vazios, espaços e 1.472 nulos | `Female` / `Male` / `n/a` |

## erp_loc_a101
| Problema encontrado | Regra aplicada |
|---|---|
| `cid` com hífen (`AW-00011000`) | Remove o hífen; passa a casar com `cst_key` |
| Países em siglas (`DE`, `US`, `USA`), 332 nulos e 5 vazios | `Germany` / `United States` / `n/a`; demais com `TRIM` |

## erp_px_cat_g1v2
Sem problemas: carga direta, sem transformação.

## Pontos em aberto para a Gold
- **Gênero em dois sistemas:** o CRM está `n/a` para 4.569 clientes; o ERP tem o dado de 4.554 deles. Em 57 clientes os dois sistemas **discordam**. Regra a definir na Gold (candidata: CRM prevalece; ERP só preenche quando o CRM é `n/a`).
- **Categoria sem cadastro:** o `cat_id` `CO_PE` existe nos produtos, mas não em `erp_px_cat_g1v2`. Na Gold, o JOIN deve ser `LEFT` para o produto não sumir.

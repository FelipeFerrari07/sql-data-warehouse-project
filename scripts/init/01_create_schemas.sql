/*
===============================================================================
01 - Criar os schemas das camadas
===============================================================================
Objetivo:
    Cria um schema para cada camada da arquitetura medalhão:
        bronze -> dados brutos, exatamente como vieram da origem (CSV)
        silver -> dados limpos, padronizados e integrados
        gold   -> modelo analítico (estrela) pronto para consumo

Como executar (pgAdmin 4):
    1. Conecte no banco "data_warehouse" (criado no arquivo 00).
    2. Abra a Query Tool nesse banco e execute este arquivo.

Observação:
    IF NOT EXISTS torna o script seguro para rodar mais de uma vez
    (não dá erro nem apaga nada se os schemas já existirem).
===============================================================================
*/

CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

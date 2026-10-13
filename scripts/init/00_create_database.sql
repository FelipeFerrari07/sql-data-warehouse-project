/*
===============================================================================
00 - Criar o banco de dados
===============================================================================
Objetivo:
    Cria o banco "data_warehouse", que vai abrigar as três camadas
    (bronze, silver e gold) da arquitetura medalhão.

Como executar (pgAdmin 4):
    1. Conecte no banco padrão "postgres" (NÃO dentro de data_warehouse).
    2. Abra a Query Tool e execute SOMENTE este arquivo.

Por que fica em um arquivo separado?
    No PostgreSQL, CREATE DATABASE não pode rodar dentro de um bloco de
    transação nem junto de outros comandos no mesmo lote. Por isso a criação
    do banco é um passo isolado, e a criação dos schemas fica no arquivo 01.

Equivalente no SQL Server (vídeo): CREATE DATABASE DataWarehouse; USE DataWarehouse;
    (no PostgreSQL não existe USE: troca-se de banco pela conexão).
===============================================================================
*/

CREATE DATABASE data_warehouse;

/*
-- RECRIAR DO ZERO (use só se quiser apagar tudo e começar de novo!)
-- ATENÇÃO: apaga o banco inteiro e todos os dados. Exige PostgreSQL 13+.
-- DROP DATABASE IF EXISTS data_warehouse WITH (FORCE);
-- CREATE DATABASE data_warehouse;
*/

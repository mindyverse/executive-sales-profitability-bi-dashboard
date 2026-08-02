/*
01_create_database.sql

Purpose:
Create the local PostgreSQL database used for the Grocery Retail Executive
Sales and Profitability BI Dashboard project.

Run note:
For the first beginner setup, the database can be created through pgAdmin UI.
This script documents the equivalent SQL command.

Important:
Run this while connected to the default postgres database, not while connected
to grocery_retail_bi itself.

Do not store passwords in this file.
*/

CREATE DATABASE grocery_retail_bi
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    CONNECTION LIMIT = -1;
    
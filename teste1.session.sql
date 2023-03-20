
--Creates the schema
CREATE SCHEMA my_schema;

--Creates the "transcations" table
CREATE TABLE my_schema.transaction
(
    id integer NOT NULL,
    bank varchar(50) NOT NULL,
    destination varchar(50) NOT NULL,
    detail varchar(50) NOT NULL,
    method varchar(50) NOT NULL,
    tr_date timestamp with time zone NOT NULL,
    tr_value money NOT NULL,
    currency varchar(3) DEFAULT 'BRL' NOT NULL
);

--Defines the primary key
ALTER TABLE my_schema.transaction
ADD CONSTRAINT pk_transaction
PRIMARY KEY (id);

--Sets the currency type to generic which includes negative sign
SET lc_monetary TO 'C';

-- Adds a tuple with tr_value = 0 to avoid generating null values on further views and tables (e.g.  bank_summary_c6)
INSERT INTO my_schema.transaction
VALUES (-1, 'XXXX', 'XXXX', 'XXXX', 'XXXX', '2000-01-01 00:00:00-02', 0, 'USD');


--Adding values HARD CODED
INSERT INTO my_schema.transaction
    VALUES (1, 'C6', 'Mercado Livre', 'Tênis', 'pix', '2023-02-01', -150.19910, 'USD'),
    (2, 'C6', 'Amazon', 'Livro X', 'credito', '2023-02-01 14:05:06', 150.10, 'USD'),
    (3, 'Bradesco', 'Ifood', 'Wiki Poke', 'debito', '2023-03-01 14:05:06', 50.00, 'USD'),
    (4, 'Bradesco', 'Smart Fit', 'Mensalidade', 'pix', '2023-02-05 11:05:06', 120, 'USD'),
    (5, 'C6', 'Amazon', 'Livro X', 'credito', '2023-02-01 14:05:06', 22.0, 'USD'),
    (6, 'Bradesco', 'Ifood', 'Wiki Poke', 'debito', '2023-03-01 14:05:06', -10, 'USD'),
    (7, 'Bradesco', 'Smart Fit', 'Mensalidade', 'pix', '2023-02-05 11:05:06', 300, 'USD'),
    (8, 'Bradesco', 'Smart Fit', 'Mensalidade', 'pix', '2023-02-05 11:05:06', 110, 'USD'),
    (9, 'C6', 'Smart Fit', 'Mensalidade', 'pix', '2023-02-05 11:05:06', 110, 'USD'),
    (10, 'C6', 'Smart Fit', 'Mensalidade', 'pix', '2023-02-05 11:05:06', 33, 'USD');


-- Stored Procedure to create the views (tr_in_BANK, tr_out_BANK and bank_summary_BANK)
-- in a specific time period ([time_period[1], time_period[2]])
DROP PROCEDURE create_bank_views(bank_list varchar[], time_period timestamp with time zone[]) CASCADE;
CREATE OR REPLACE PROCEDURE create_bank_views(bank_list varchar[], time_period timestamp with time zone[])
AS $$
DECLARE
    bank_name varchar;
    time_period_beginning timestamp with time zone := time_period[1];
    time_period_end timestamp with time zone := time_period[2];
BEGIN
    FOREACH bank_name IN ARRAY bank_list
    LOOP
        -- 2 views (1 with all the positive and 0 tr_values and 1 with all the negative and 0 tr_values) 
        -- Drops pre-existing view and verifies if it belongs to the bank of the iteration, whether it is
        -- within the time period, whether it is positive/negative (or equal to zero).
        -- The XXXX tuple is added in all cases
        EXECUTE 'DROP VIEW IF EXISTS tr_in_' || bank_name || ' CASCADE;';
        EXECUTE 'CREATE VIEW tr_in_' || bank_name || ' AS
        (
            SELECT *
            FROM my_schema.transaction AS t
            WHERE (t.bank = ''' || bank_name || '''
            AND t.tr_date BETWEEN ''' || time_period_beginning || ''' AND  ''' || time_period_end || '''
            AND CAST(t.tr_value AS NUMERIC) >= 0
            )
            OR t.bank = ''XXXX''
        );';

        EXECUTE 'DROP VIEW IF EXISTS tr_out_' || bank_name || ' CASCADE;';
        EXECUTE 'CREATE VIEW tr_out_' || bank_name || ' AS
        (
            SELECT *
            FROM my_schema.transaction AS t
            WHERE (t.bank = ''' || bank_name || '''
            AND t.tr_date BETWEEN ''' || time_period_beginning || ''' AND  ''' || time_period_end || '''
            AND CAST(t.tr_value AS NUMERIC) <= 0
            )
            OR t.bank = ''XXXX''
        );';

        -- View with 3 columns (sum of tr_values in tr_in_BANK, sum of tr_values in tr_out_BANK, 
        -- the difference of these 2 sums)
        -- The subquery "flow_in" has the sum of tr_values in tr_in_BANK.
        -- The subquery "flow_out" has the sum of tr_values in tr_out_BANK.
        -- Since a cross  join is being executed (~lateral concatanation), the output of flow_in and flow_out must contain only
        -- one cell (1 row and 1 column). Therefore, watch out for the generation of extra rows with NULL and '0'.
        -- Note: the XXXX tuple makes it possible for the cross join to work when there are no tuples or no tuples with positive/negative
        -- values in tr_in_BANK/tr_out_BANK. So it is important to initialize the transactions table with the X tuple to avoid error propagation.
        EXECUTE 'DROP VIEW IF EXISTS bank_summary_' || bank_name || ' CASCADE;';
        EXECUTE 'CREATE VIEW bank_summary_' || bank_name || ' AS
        (
            SELECT flow_in.tr_value_sum AS flow_in, flow_out.tr_value_sum AS flow_out, flow_in.tr_value_sum + flow_out.tr_value_sum AS balance,
            ''' || time_period_beginning || ''' AS time_period_beginning, ''' || time_period_end || ''' AS time_period_end
            FROM(
                SELECT
                    SUM(CASE WHEN CAST(t.tr_value AS NUMERIC) >= 0 THEN CAST(t.tr_value AS NUMERIC) END) AS tr_value_sum
                FROM tr_in_' || bank_name || ' AS t
                GROUP BY
                    CAST(t.tr_value AS NUMERIC) >= 0
                HAVING
                    SUM(CASE WHEN CAST(t.tr_value AS NUMERIC) >= 0 THEN CAST(t.tr_value AS NUMERIC) END) IS NOT NULL
            ) AS flow_in,
            (
                SELECT
                    SUM(CASE WHEN CAST(t.tr_value AS NUMERIC) <= 0 THEN CAST(t.tr_value AS NUMERIC) END) AS tr_value_sum
                FROM tr_out_' || bank_name || ' AS t
                GROUP BY
                    CAST(t.tr_value AS NUMERIC) <= 0
                HAVING
                    SUM(CASE WHEN CAST(t.tr_value AS NUMERIC) <= 0 THEN CAST(t.tr_value AS NUMERIC) END) IS NOT NULL
            ) AS flow_out
        );';

    END LOOP;
END;
$$ LANGUAGE plpgsql;



--------------------------------------------------
-- See table with its tuples
SELECT * FROM my_schema.transaction;


CALL create_bank_views(ARRAY['C6', 'Bradesco'], ARRAY['2023-02-01 00:00:00-02', '2023-02-03 23:59:59-02']::timestamp with time zone[]);

SELECT *
FROM tr_in_c6;
SELECT *
FROM tr_out_c6;

SELECT *
FROM tr_in_bradesco;
SELECT *
FROM tr_out_bradesco;

SELECT * FROM bank_summary_c6;

-- Restart
DROP SCHEMA my_schema CASCADE;

DROP VIEW transactionbank_c6;

DELETE FROM my_schema.transaction;
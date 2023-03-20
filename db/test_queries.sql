CREATE TABLE transaction
(
    id integer Not Null,
    bank varchar(50) Not Null,
    destination varchar(50) Not Null,
    detail varchar(50) Not Null,
    tr_date datetime Not Null,
    tr_value char(8) Not Null
);
ALTER TABLE transaction
ADD CONSTRAINT pk_transaction
PRIMARY KEY (id);
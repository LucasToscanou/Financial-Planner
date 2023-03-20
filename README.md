# Financial-Planner
A SQL based app that organizes the accounting of bank accounts, creating summaries to each bank account, investment summaries and a general summary that gathers information from all the accounts.

**Current Version: 0.1.0**

## What is done
- Creation of the schema and the transactions table (the most essential one because it is used to generate most views)
- Addition of sample data to help with development and make the output visible
- Creation of the Procedure to create the views tr_in, tr_out and bank_summary_BANK for each bank in a list of banks and within a time period.


## What is ther to be done
- Figure out a way to have in the same table: money_in, money_out, balance, time period, money_total
  - Note: money_total is the current amount of money in the account
  - Note: this table should be able to contain multiple tuples
  - Time period should act as a primary key (not necessarily as a date, it could be in weeks: week 1, week 2, ...)
 - Create an investment table for each bank account (Also create a investment transactions table that includes the profitability, expiration date, ...)
 - Create an general summary table that includes the transactions and investments
 - Create a UI
   - Display tables
   - Display graphs
   - Be able to add transactions and investments
  
 - Consider CRUD
 - Create a future wealth projection system
 - Connect to stock market indexes
 
 
 

# spo2ns

Script loads a Shopify Payouts CSV export and output a NetSuite CSV GL Import

Adds all fees and creates 2 GL entries per day one for fees expense other for deposit to bank account.

## Usage

spo2ns.rb &lt;strftime format str&gt; &lt;bank acct&gt; &lt;shopify "bank" acct&gt; &lt;fees acct&gt; &lt;po exports.csv&gt;

Ex:
```
C:\Users\Brad Krane\Documents\src\spo2ns>ruby spo2ns.rb %d-%b-%y 11500 11600 65300 "shopify payouts ENTIRE history to March 4 2022.csv" | more
Date,Account,Credit,Debit,Memo
04-Mar-22,11600,663.91,0,Shopify Payout to Bank 04-Mar-22 
04-Mar-22,11500,0,663.91,Shopify Payout to Bank 04-Mar-22 
04-Mar-22,11600,19.41,0,Shopify Fees Expense 04-Mar-22    
04-Mar-22,65300,0,19.41,Shopify Fees Expense 04-Mar-22    
03-Mar-22,11600,472.42,0,Shopify Payout to Bank 03-Mar-22 
03-Mar-22,11500,0,472.42,Shopify Payout to Bank 03-Mar-22 
03-Mar-22,11600,15.61,0,Shopify Fees Expense 03-Mar-22    
03-Mar-22,65300,0,15.61,Shopify Fees Expense 03-Mar-22    
02-Mar-22,11600,1477.61,0,Shopify Payout to Bank 02-Mar-22
02-Mar-22,11500,0,1477.61,Shopify Payout to Bank 02-Mar-22
02-Mar-22,11600,43.91,0,Shopify Fees Expense 02-Mar-22    
02-Mar-22,65300,0,43.91,Shopify Fees Expense 02-Mar-22    
01-Mar-22,11600,1100.17,0,Shopify Payout to Bank 01-Mar-22
01-Mar-22,11500,0,1100.17,Shopify Payout to Bank 01-Mar-22
01-Mar-22,11600,29.21,0,Shopify Fees Expense 01-Mar-22    
01-Mar-22,65300,0,29.21,Shopify Fees Expense 01-Mar-22    
28-Feb-22,11600,175.57,0,Shopify Payout to Bank 28-Feb-22 
28-Feb-22,11500,0,175.57,Shopify Payout to Bank 28-Feb-22 
28-Feb-22,11600,5.24,0,Shopify Fees Expense 28-Feb-22     
28-Feb-22,65300,0,5.24,Shopify Fees Expense 28-Feb-22 
```

## NetSuite Import Mappings

```
Memo                ↔ Journal Entry : Memo
<Company default>   ↔ Journal Entry : Subsidiary (Req)
Date                ↔ Journal Entry : Date (Req)
Memo                ↔ Journal Entry : Entry No.
Account             ↔ Journal Entry - Line : Account
Credit              ↔ Journal Entry - Line : Credit	
Debit               ↔ Journal Entry - Line : Debit
<Location default>  ↔ Journal Entry - Line : Location
Memo                ↔ Journal Entry - Line : Memo
```

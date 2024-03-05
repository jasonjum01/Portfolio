/*
customers table contains sensitive info such as business name, owners full name, contact information, residency, and credit availability.

employee table contains basic information such as full name, work email, their work id and who they report to.

office table contains 7 locations of their office spaces throughout the U.S.

orderdetail tables contain products ordered, quantity and the price for the total order made.

orders table contain dates on when ordered took place, when order has been shipped and when it needs to be shipped by as well as any comments on the order.

payment table cointains customer number with payment amounts, when payment was made with the checking number.

productline table group of products with description of each product. 

product table contains each product with productline categorization and description of each product following with quantity in stock, also has the buy price and MSRP.
*/

-- I was first tasked to create a query that displays the table name, number of columns as well as the total rows
SELECT 'Customers' AS table_name,
       (SELECT COUNT(*) 
        FROM pragma_table_info('Customers')
        ) AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM Customers

UNION ALL 

SELECT 'Products' AS table_name,
       (SELECT COUNT(*) 
        FROM pragma_table_info('Products')
        ) AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM Products

UNION ALL

SELECT 'ProductLines' AS table_name,
       (SELECT COUNT(*) 
        FROM pragma_table_info('ProductLines')
        ) AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM ProductLines
  
UNION ALL 

SELECT 'Orders' AS table_name,
       (SELECT COUNT(*) 
        FROM pragma_table_info('Orders')
        ) AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM Orders
  
UNION ALL

SELECT 'OrderDetails' AS table_name,
       (SELECT COUNT(*) 
        FROM pragma_table_info('OrderDetails')
        ) AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM OrderDetails

UNION ALL
 
SELECT 'Payments' AS table_name,
       (SELECT COUNT(*) 
        FROM pragma_table_info('Payments')
        ) AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM Payments

UNION ALL

SELECT 'Employees' AS table_name,
       (SELECT COUNT(*) 
        FROM pragma_table_info('Employees')
        ) AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM Employees

UNION ALL

SELECT 'Offices' AS table_name,
       (SELECT COUNT(*) 
        FROM pragma_table_info('Offices')
        ) AS number_of_attributes,
       COUNT(*) AS number_of_rows
  FROM Offices;

 /* 
 Q1: Which Products Should We Order More Of Or Less Of?
 So here we're trying to find products that have the highest in sales/out-of-stock and/or products that are simply
 not selling well. In order to answer these questions we will need to perform these following calculations:
 low stock = SUM(quantityOrdered)/quantityInStock) & product performance = SUM(quantityOrdered * EachPrice)
 */
 
WITH 
restock AS (
-- low stock table
 SELECT productCode, 
        ROUND(SUM(o.quantityOrdered) / 
             (SELECT p.quantityInStock
                FROM products AS p
               WHERE o.productCode = p.productCode),2) AS low_stock
   FROM orderdetails AS o
  GROUP BY productCode
  ORDER BY low_stock DESC
  LIMIT 10
)

 SELECT (SELECT productName FROM products p WHERE p.productCode = o.productCode) AS                     product_name, 
        productCode,
        SUM(quantityOrdered * priceEach) AS product_performance
   FROM orderdetails o
-- used CTE to match productCode with product performance
  WHERE productCode IN (SELECT productCode
                          FROM restock)
  GROUP BY productCode
  ORDER BY product_performance DESC
  LIMIT 10;
 
/*
 Q2P1 How Should We Match Marketing and Communication Strategies to Customer Behavior?
 Here this question is asking us to categorize their customers by two groups.. VIP customers and less engaged customers. 
 And the result of the query will help how to approach their marketing strategies.
 before we start organizing, first we need to generate profit is made with each customer.
 */
 -- profit that comes from each customer
 SELECT customerNumber,
       SUM(od.quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM orders AS o
 INNER JOIN orderdetails AS od
    ON o.orderNumber = od.orderNumber
 INNER JOIN products AS p
    ON od.productCode = p.productCode 
 GROUP BY customerNumber;
 
 /*
 Q2P2 Now that we have a query we can begin grouping our customers, and to achieve this I'll be using a CTE to find the 
 TOP 5 VIP Customers. 
 */
 -- creating CTE from profits of each customer
 
WITH 
top_five AS (
    SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber)

-- Top Five VIP Customers
SELECT c.contactLastName, 
       c.contactFirstName, 
       c.city, 
       tf.profit
  FROM customers AS c
 INNER JOIN top_five AS tf
    ON c.customerNumber = tf.customerNumber
 ORDER BY profit DESC
 LIMIT 5;
 
 WITH 
top_five AS (
    SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber)
 
-- Top Five Least-engaged Customers 
SELECT c.contactLastName, 
       c.contactFirstName, 
       c.city, 
       tf.profit
  FROM customers AS c
 INNER JOIN top_five AS tf
    ON c.customerNumber = tf.customerNumber
 ORDER BY profit ASC
 LIMIT 5;
 
 /* Q3 How Much Can We Spend on Acquiring New Customers?
 In order to answer this quesiton, it state that we have to compute the
 Customer Lifetime Value(LTV), which represents the average money a customer spends.
 To solve this all I had to do was grab my top_five CTE I created previously and 
 average the profits.
 */
 
 WITH top_five AS (
    SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber
)
    
SELECT AVG(profit) AS LTV
  FROM top_five
 


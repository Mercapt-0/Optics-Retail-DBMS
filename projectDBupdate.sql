--Insert sample purchases
--Insert sample purchases (use pairs not present in `projectDBinsert.sql` to avoid duplicates)
INSERT INTO Fall25_S003_T8_BUYS (cust_person_id, product_id) VALUES (1, 21);
INSERT INTO Fall25_S003_T8_BUYS (cust_person_id, product_id) VALUES (2, 22);

--Insert sample purchase details (matching the new pairs)
INSERT INTO Fall25_S003_T8_BUYS_details (cust_person_id, product_id, buy_date, warr_no, payment_method, total_sale_value, quantity)
VALUES (1, 21, TO_DATE('2024-11-01', 'YYYY-MM-DD'), 'W2024021', 'Debit Card', 145.00, 1);

INSERT INTO Fall25_S003_T8_BUYS_details (cust_person_id, product_id, buy_date, warr_no, payment_method, total_sale_value, quantity)
VALUES (2, 22, TO_DATE('2024-11-02', 'YYYY-MM-DD'), 'W2024022', 'PayPal', 207.00, 1);

--Update product attribute
UPDATE Fall25_S003_T8_PRODUCT SET size_mm = '10 inches' WHERE product_id = 15;

--Update supply quantities
UPDATE Fall25_S003_T8_SUPPLIES_details SET quantity = 1 WHERE product_id = 36;
UPDATE Fall25_S003_T8_SUPPLIES_details SET quantity = 1000 WHERE product_id = 43;

--Delete sells details by employee
DELETE FROM Fall25_S003_T8_SELLS_details WHERE emp_person_id = 52;

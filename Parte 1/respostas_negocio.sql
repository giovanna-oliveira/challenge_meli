USE challenge_meli;

/*
1. Listar os usuários que fazem aniversário no dia de hoje e que a quantidade de vendas realizadas em Janeiro/2020 sejam superiores a 1500;
 */
SELECT 
	-- seller info
	c.customer_id,
	c.email,
    c.first_name,
    -- order quantity
    COALESCE(o.order_qt,0) AS order_qt
FROM Customers AS c
LEFT JOIN 
	-- selecting and counting orders made in jan/2020 and grouping by seller
	(SELECT 
		seller_fk,
		COUNT(order_id) AS order_qt
	 FROM Orders
     WHERE created_at BETWEEN '2020-01-01' AND '2020-01-31'
     GROUP BY seller_fk) AS o
    -- joining customer rows with order info by seller_fk, retrieving only their sales
	ON c.customer_id = o.seller_fk
WHERE
	-- filtering birthdays using curdate as today's date
	DAY(c.birth_date) = DAY(CURDATE()) 
    AND MONTH(c.birth_date) = MONTH(CURDATE())
    -- filtering customers with more than 1500 sales
    AND order_qt > 1500;
   
   
   
/*
2. Para cada mês de 2020, solicitamos que seja exibido um top 5 dos usuários que mais venderam ($) na categoria Celulares. Solicitamos o mês e ano da análise,
nome e sobrenome do vendedor, quantidade de vendas realizadas, quantidade de produtos vendidos e o total vendido;
*/
SELECT 
	-- seller info
	first_name,
	last_name,
	-- order info
	order_year,
	order_month,
	sales_qt,
	products_sold,
	income
FROM
	(SELECT 
		-- seller info
		c.first_name,
		c.last_name,
		-- order info
		YEAR(o.created_at) AS order_year,
		MONTH(o.created_at) AS order_month,
		COALESCE(COUNT(o.order_id),0) AS sales_qt,
		COALESCE(SUM(o.quantity),0) AS products_sold,
		COALESCE(SUM(o.quantity * o.price),0) AS income,
        -- ranking the income on a monthly basis
		ROW_NUMBER() OVER (PARTITION BY MONTH(o.created_at) ORDER BY COALESCE(SUM(o.quantity * o.price),0) DESC) AS income_rank 
	FROM Orders AS o
	LEFT JOIN 
		-- collecting seller info (first and last name)
		(SELECT 
			customer_id,
			first_name,
			last_name
		FROM Customers) AS c 
	ON o.seller_fk = c.customer_id
	LEFT JOIN 
		-- collecting the item category_name
		(SELECT 
			item_id,
			ca.category_name
		FROM Items
		LEFT JOIN Categories AS ca
		ON category_fk = ca.category_id) AS i
	ON o.item_fk = i.item_id
	WHERE 
		YEAR(o.created_at) = 2020
		AND i.category_name = 'Celulares'
	GROUP BY 
		c.first_name,
		c.last_name,
		YEAR(o.created_at),
		MONTH(o.created_at)
) ranking
-- printing only the 5 sellers with the most income per month
WHERE income_rank <= 5
ORDER BY 
	order_month ASC,
    income DESC;


/*
3. Solicitamos popular uma nova tabela com o preço e estado dos itens no final do dia. Considerar que esse processo deve permitir um reprocesso. Vale ressaltar que na
tabela de item, vamos ter unicamente o último estado informado pela PK definida (esse item pode ser resolvido através de uma store procedure).
*/
DELIMITER $$
CREATE PROCEDURE SP_insert_item_history()
BEGIN
	-- variables used to store info 
	DECLARE end_loop INT DEFAULT FALSE;
    DECLARE sp_item_fk INT;
    DECLARE sp_price DECIMAL(10,2);
    DECLARE sp_item_status TINYINT;
    DECLARE sp_processing_date DATE DEFAULT CURDATE();
    -- retrieving all items from Item Table
    DECLARE item_cursor CURSOR FOR
		SELECT 
			item_id, 
            price, 
            item_status
        FROM Items
        /*WHERE 
			-- filtering only active items
			end_date IS NULL
            OR end_date >= CURDATE()*/;
	
    DECLARE 
		CONTINUE HANDLER FOR NOT FOUND 
	SET end_loop = TRUE;
    OPEN item_cursor;
    item_loop: LOOP
		-- retrieves info from next row returned from previous select statement
		FETCH item_cursor 
        INTO 
			sp_item_fk, 
            sp_price, 
            sp_item_status;

        IF end_loop THEN
            LEAVE item_loop;
        END IF;
        -- insert or update item values
		INSERT INTO Item_history (item_fk, price, item_status, processing_date)
		VALUES (sp_item_fk, sp_price, sp_item_status, sp_processing_date)
        -- if the constraint key (UC_Item_history) already exists, the price and item_status values will be updated, otherwise a new row will be created
		ON DUPLICATE KEY UPDATE
			price = sp_price,
			item_status = sp_item_status;
	END LOOP;
    CLOSE item_cursor;
END $$
DELIMITER $$;

CALL SP_insert_item_history();
SELECT * FROM Item_history;


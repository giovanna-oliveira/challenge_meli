CREATE DATABASE IF NOT EXISTS challenge_meli;
USE challenge_meli;

CREATE TABLE IF NOT EXISTS Customers (
	customer_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(255) NOT NULL,
	last_name VARCHAR(255) NOT NULL,
    gender VARCHAR(45),
    birth_date DATE,
    -- address
    country VARCHAR(2), -- ISO 3166-1 alpha-2, only 2 characters necessary
    sub_administrative_area VARCHAR(255), -- district / state
    locality VARCHAR(255), -- city
    postal_code VARCHAR(45), -- zip code / CEP
    thoroughfare VARCHAR(255), -- street adress
    premise VARCHAR(255)  -- apartment or other additional reference
);

CREATE TABLE IF NOT EXISTS Categories (
	category_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    category_name VARCHAR(255) NOT NULL,
    parent_category INT,
    FOREIGN KEY (parent_category) REFERENCES Categories(category_id)
);

CREATE TABLE IF NOT EXISTS Items(
	item_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    item_name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    end_date DATETIME(6),
    item_status TINYINT NOT NULL, -- 1 for active, 0 for inactive
    category_fk INT NOT NULL,
    FOREIGN KEY (category_fk) REFERENCES Categories(category_id)
);

CREATE TABLE IF NOT EXISTS Orders(
	order_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
	buyer_fk INT NOT NULL, -- references Customers Table
    seller_fk INT NOT NULL, -- references Customers Table
    item_fk INT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10,2) NOT NULL, -- price per unity
    created_at DATETIME(6),
    FOREIGN KEY (buyer_fk) REFERENCES Customers(customer_id),
    FOREIGN KEY (seller_fk) REFERENCES Customers(customer_id),
    FOREIGN KEY (item_fk) REFERENCES Items(item_id)
);

-- created for the third question
CREATE TABLE IF NOT EXISTS Item_history(
	item_fk INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    item_status TINYINT NOT NULL,
    processing_date DATE NOT NULL,
    CONSTRAINT UC_item_history UNIQUE (item_fk,processing_date)
);




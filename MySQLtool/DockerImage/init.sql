-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS user_details;

-- Use the user_details database
USE user_details;

-- Create a new table in the database
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(50) NOT NULL,
    product_id INT(10) NOT NULL,
    product_name VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

-- Insert some sample data into the table
INSERT INTO users (username, email, product_id, product_name, price) VALUES 
('Aayush', 'aayushverma@gmail.com', 34562, 'Bedsheet', 999.99),
('Raj', 'raj.123@gmail.com', 7854, 'Wall Lighting', 1599.99),
('Prashant', 'prahant@outlook.com', 6598, 'Ear Wired Earphones', 499.00);

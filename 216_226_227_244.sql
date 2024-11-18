-- Create the database
CREATE DATABASE freshbite;
USE freshbite;

-- Customer Table
CREATE TABLE customer (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone_number VARCHAR(15) NOT NULL,
    address VARCHAR(255) NOT NULL
);

-- Restaurant Table
CREATE TABLE restaurant (
    restaurant_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(255) NOT NULL
);

-- Menu Table
CREATE TABLE menu (
    menu_item_id INT PRIMARY KEY AUTO_INCREMENT,
    restaurant_id INT NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    availability BOOLEAN NOT NULL,
    FOREIGN KEY (restaurant_id) REFERENCES restaurant(restaurant_id)
);

-- Order Table
CREATE TABLE `order` (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    order_status VARCHAR(50) NOT NULL,
    order_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurant(restaurant_id)
);

-- Order Items Table
CREATE TABLE order_item (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    menu_item_id INT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES `order`(order_id),
    FOREIGN KEY (menu_item_id) REFERENCES menu(menu_item_id)
);

-- Delivery Table
CREATE TABLE delivery (
    delivery_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    delivery_person VARCHAR(100) NOT NULL,
    delivery_status VARCHAR(50) NOT NULL,
    delivery_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES `order`(order_id)
);

-- Review Table
CREATE TABLE review (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    review_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurant(restaurant_id)
);


SELECT * FROM customer;
SELECT * FROM restaurant;
SELECT * FROM menu;
SELECT * FROM `order`;
SELECT * FROM order_item;
SELECT * FROM delivery;
SELECT * FROM review;


-- Sample data insertion for each table
-- Customers
INSERT INTO customer (name, email, phone_number, address) VALUES
('John Doe', 'john@email.com', '1234567890', '123 Main St'),
('Jane Smith', 'jane@email.com', '2345678901', '456 Oak Ave'),
('Bob Wilson', 'bob@email.com', '3456789012', '789 Pine Rd'),
('Alice Brown', 'alice@email.com', '4567890123', '321 Maple Dr'),
('Charlie Davis', 'charlie@email.com', '5678901234', '654 Cedar Ln');

-- Restaurants
INSERT INTO restaurant (name, location) VALUES
('Spice Palace', '100 Food Court'),
('Burger Heaven', '200 Fast Lane'),
('Pizza Paradise', '300 Italian Way'),
('Sushi Supreme', '400 Ocean Drive'),
('Veggie Delight', '500 Green Street');

-- Menu Items
INSERT INTO menu (restaurant_id, item_name, price, availability) VALUES
(1, 'Butter Chicken', 15.99, true),
(1, 'Naan Bread', 3.99, true),
(2, 'Classic Burger', 12.99, true),
(2, 'French Fries', 4.99, true),
(3, 'Margherita Pizza', 18.99, true);

-- Orders
INSERT INTO `order` (customer_id, restaurant_id, total_price, order_status, order_time) VALUES
(1, 1, 35.98, 'Delivered', '2024-03-15 12:00:00'),
(2, 2, 22.97, 'Placed', '2024-03-15 12:30:00'),
(3, 3, 18.99, 'Cancelled', '2024-03-15 13:00:00'),
(4, 1, 19.98, 'Delivered', '2024-03-15 13:30:00'),
(5, 2, 17.98, 'Placed', '2024-03-15 14:00:00');

-- Order Items
INSERT INTO order_item (order_id, menu_item_id, quantity, price) VALUES
(1, 1, 2, 31.98),
(1, 2, 1, 3.99),
(2, 3, 1, 12.99),
(2, 4, 2, 9.98),
(3, 5, 1, 18.99);

-- Deliveries
INSERT INTO delivery (order_id, delivery_person, delivery_status, delivery_time) VALUES
(1, 'Mike Johnson', 'Delivered', '2024-03-15 12:45:00'),
(2, 'Sarah Williams', 'Assigned', '2024-03-15 13:00:00'),
(3, 'Tom Brown', 'In Progress', '2024-03-15 13:30:00'),
(4, 'Lisa Davis', 'Delivered', '2024-03-15 14:15:00'),
(5, 'David Wilson', 'Assigned', '2024-03-15 14:30:00');

-- Reviews
INSERT INTO review (customer_id, restaurant_id, rating, review_text) VALUES
(1, 1, 5, 'Excellent food and service!'),
(2, 2, 4, 'Good burger, will order again'),
(3, 3, 5, 'Best pizza in town'),
(4, 1, 4, 'Tasty food but delivery was a bit late'),
(5, 2, 3, 'Decent food, could be better');



SELECT * FROM customer;
SELECT * FROM restaurant;
SELECT * FROM menu;
SELECT * FROM `order`;
SELECT * FROM order_item;
SELECT * FROM delivery;
SELECT * FROM review;




--Question 4

-- First delete related records in child tables
DELETE FROM delivery 
WHERE order_id IN (SELECT order_id FROM `order` WHERE order_status = 'Cancelled');

DELETE FROM order_item 
WHERE order_id IN (SELECT order_id FROM `order` WHERE order_status = 'Cancelled');

-- Then delete from the main order table
DELETE FROM `order` 
WHERE order_status = 'Cancelled';






--Question 5
WITH RECURSIVE CustomerRestaurants AS (
    -- Base case: Get all distinct customer-restaurant combinations
    SELECT 
        customer_id,
        COUNT(DISTINCT restaurant_id) as restaurant_count
    FROM `order`
    GROUP BY customer_id
)
SELECT 
    c.name,
    COALESCE(cr.restaurant_count, 0) as unique_restaurants
FROM customer c
LEFT JOIN CustomerRestaurants cr ON c.customer_id = cr.customer_id
ORDER BY unique_restaurants DESC;




--Question 6

DELIMITER //

CREATE PROCEDURE transfer_delivery(
    IN p_order_id INT,
    IN p_old_agent VARCHAR(100),
    IN p_new_agent VARCHAR(100)
)
BEGIN
    DECLARE v_delivery_status VARCHAR(50);
    
    -- Check if order exists and is not delivered
    SELECT delivery_status INTO v_delivery_status
    FROM delivery
    WHERE order_id = p_order_id AND delivery_person = p_old_agent;
    
    IF v_delivery_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Order not found or agent mismatch';
    ELSEIF v_delivery_status = 'Delivered' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot transfer delivered orders';
    ELSE
        -- Update the delivery record with new agent and status
        UPDATE delivery
        SET delivery_person = p_new_agent,
            delivery_status = CONCAT('Reassigned from ', p_old_agent),
            delivery_time = CURRENT_TIMESTAMP
        WHERE order_id = p_order_id 
        AND delivery_person = p_old_agent;
        
        SELECT CONCAT('Order ', p_order_id, ' successfully transferred from ', 
                     p_old_agent, ' to ', p_new_agent) AS message;
    END IF;
END //

DELIMITER ;


-- Test the transfer
CALL transfer_delivery(2, 'Sarah Williams', 'Mike Johnson');

-- Verify the transfer
SELECT * FROM delivery WHERE order_id = 2;








-- Question 7

DELIMITER //

CREATE TRIGGER prevent_incomplete_order_reviews
BEFORE INSERT ON review
FOR EACH ROW
BEGIN
    DECLARE order_count INT;
    
    SELECT COUNT(*) INTO order_count
    FROM `order`
    WHERE customer_id = NEW.customer_id 
    AND restaurant_id = NEW.restaurant_id
    AND order_status = 'Delivered';
    
    IF order_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Reviews can only be submitted for completed orders';
    END IF;
END //

DELIMITER ;







--Question 8

-- Simulate Transaction T1 (Assuming it's causing the lock)
START TRANSACTION;

-- Example: T1 locks OrderID=10
SELECT * FROM `order` WHERE order_id = 4 FOR UPDATE;

-- Simulate delay in releasing the lock
DO SLEEP(30);

-- Commit or Rollback T1 (unlocking the rows)
COMMIT;

-- Simulate Transaction T2
START TRANSACTION;

-- First UPDATE in T2 (Fails due to lock timeout)
UPDATE `order`
SET total_price = total_price - 50
WHERE order_id = 4;

-- Commit Transaction T2
COMMIT;

-- Check the updated rows
SELECT * FROM `order`;





--Question 9

-- First, create the function
DELIMITER //

CREATE FUNCTION restaurant_rating_summary(p_restaurant_id INT) 
RETURNS VARCHAR(255)
READS SQL DATA
BEGIN
    DECLARE total_ratings INT;
    DECLARE avg_rating DECIMAL(4,2);
    DECLARE five_star_percent DECIMAL(4,1);

    -- Get total ratings
    SELECT COUNT(*) INTO total_ratings
    FROM review 
    WHERE restaurant_id = p_restaurant_id;

    IF total_ratings = 0 THEN
        RETURN NULL;
    END IF;

    -- Calculate average rating
    SELECT ROUND(AVG(rating), 2) INTO avg_rating
    FROM review 
    WHERE restaurant_id = p_restaurant_id;

    -- Calculate percentage of 5-star ratings
    SELECT ROUND(COUNT(*) * 100.0 / total_ratings, 1) INTO five_star_percent
    FROM review 
    WHERE restaurant_id = p_restaurant_id 
    AND rating = 5;

    RETURN CONCAT(
        'Total Ratings: ', total_ratings,
        ', Average Rating: ', avg_rating,
        ', 5-Star Percentage: ', five_star_percent, '%'
    );
END //

DELIMITER ;

-- Now, let's call the function in different ways:

-- 1. Test for a single restaurant with reviews
SELECT 
    r.name AS restaurant_name,
    restaurant_rating_summary(r.restaurant_id) AS rating_summary
FROM restaurant r
WHERE r.restaurant_id = 1;

-- 2. Test for all restaurants to see their summaries
SELECT 
    r.restaurant_id,
    r.name AS restaurant_name,
    restaurant_rating_summary(r.restaurant_id) AS rating_summary
FROM restaurant r;

-- 3. Verification query to double-check the results
SELECT 
    r.restaurant_id,
    r.name,
    COUNT(rev.review_id) as total_ratings,
    ROUND(AVG(rev.rating), 2) as avg_rating,
    ROUND(SUM(CASE WHEN rev.rating = 5 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) as five_star_percent
FROM 
    restaurant r
LEFT JOIN 
    review rev ON r.restaurant_id = rev.restaurant_id
GROUP BY 
    r.restaurant_id, r.name;
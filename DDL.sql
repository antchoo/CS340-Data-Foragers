-- The Data Foragers
-- Group 41 CS340 Summer 2026 OSU
-- Anton Choo and Borislava Grigorova
--
-- Data Definition Queries + sample data, wrapped in the sp_load_foodmenudb()
-- stored procedure (per the sp_moviedb.sql example) so the web app's RESET
-- button can rebuild the schema and sample data with `CALL sp_load_foodmenudb();`
-- (see webapp/app.js, POST /reset).
--

DROP PROCEDURE IF EXISTS sp_load_foodmenudb;

DELIMITER //
CREATE PROCEDURE sp_load_foodmenudb()
BEGIN

SET FOREIGN_KEY_CHECKS = 0;

-- drop tables so the procedure can be re-run cleanly
DROP TABLE IF EXISTS VendorIngredients;
DROP TABLE IF EXISTS MenuItemIngredients;
DROP TABLE IF EXISTS Ingredients;
DROP TABLE IF EXISTS MenuItems;
DROP TABLE IF EXISTS Vendors;

-- create the table with menu items
CREATE TABLE MenuItems (
    menuItemID INT AUTO_INCREMENT,
    menuItemName VARCHAR(155) NOT NULL,
    menuItemTotalCost DECIMAL(4,2),
    PRIMARY KEY (menuItemID)
);

-- create the table with vendors
CREATE TABLE Vendors (
    vendorID INT AUTO_INCREMENT,
    vendorName VARCHAR(155) NOT NULL,
    vendorRepresentative VARCHAR(155),
    vendorContact VARCHAR(13),
    PRIMARY KEY (vendorID)
);

-- create the table with ingredients
CREATE TABLE Ingredients (
    ingredientID INT AUTO_INCREMENT,
    ingredientName VARCHAR(155) NOT NULL,
    -- only 'oz' and 'each' are valid units of measurement
    unitType VARCHAR(4) NOT NULL CHECK (unitType IN ('oz', 'each')),
    preferredVendorID INT,
    PRIMARY KEY (ingredientID),
    FOREIGN KEY (preferredVendorID) REFERENCES Vendors (vendorID)
    -- if a vendor is deleted, the corresponding ingredient is not deleted (FK is set to NULL instead)
    ON DELETE SET NULL
    ON UPDATE CASCADE
);

-- create the intersection table for MenuItems and Ingredients
CREATE TABLE MenuItemIngredients (
    menuItemIngredientID INT AUTO_INCREMENT,
    menuItemID INT NOT NULL,
    ingredientID INT NOT NULL,
    ingredientAmount DECIMAL(4,2) NOT NULL,
    PRIMARY KEY (menuItemIngredientID),
    FOREIGN KEY (menuItemID) REFERENCES MenuItems (menuItemID)
    -- if a menu item is deleted, the corresponding rows in MenuItemIngredients should be deleted
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    FOREIGN KEY (ingredientID) REFERENCES Ingredients (ingredientID)
    -- if an ingredient is deleted, the corresponding rows in MenuItemIngredients should be deleted
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- create the intersection table for Vendors and Ingredients
CREATE TABLE VendorIngredients (
    vendorIngredientID INT AUTO_INCREMENT,
    vendorID INT NOT NULL,
    ingredientID INT NOT NULL,
    unitCost DECIMAL(4,2) NOT NULL,
    PRIMARY KEY (vendorIngredientID),
    FOREIGN KEY (vendorID) REFERENCES Vendors (vendorID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    FOREIGN KEY (ingredientID) REFERENCES Ingredients (ingredientID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- sample data

INSERT INTO Vendors (vendorName, vendorRepresentative, vendorContact) VALUES
    ('US Foods', 'Sarah McGough', '5419917958'),
    ('Sysco', 'Marissa Zander', '4583193482'),
    ('Florence Bread Company', 'Gavin Smith', '5419012021');

INSERT INTO MenuItems (menuItemName, menuItemTotalCost) VALUES
    ('Forager Burger', 7.15),
    ('Cod Fish & Chips', 6.47),
    ('Siltcoos Salad', 4.23),
    ('Steamer Clams', 5.80),
    ('French Dip', 6.04);

INSERT INTO Ingredients (ingredientName, unitType, preferredVendorID) VALUES
    ('Bun', 'each', (SELECT vendorID FROM Vendors WHERE vendorName = 'Florence Bread Company')),
    ('Beef Patty', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods')),
    ('Mushrooms', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco')),
    ('Onions', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods')),
    ('Smoked Gouda', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco')),
    ('Lettuce', 'each', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods')),
    ('Tomato', 'each', (SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco')),
    ('Aioli', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco')),
    ('French Fries', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco')),
    ('Cod', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods')),
    ('Coleslaw mix', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods')),
    ('Coleslaw dressing', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods')),
    ('Tartar', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods')),
    ('Rice Panko', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods')),
    ('Rice Flour', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods')),
    ('Egg', 'each', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods')),
    ('Mixed Greens', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco')),
    ('Hazelnuts', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods')),
    ('Pepitas', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods')),
    ('Cranberries', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods')),
    ('Blue Cheese', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco')),
    ('Salad Dressing', 'oz', NULL),
    ('Clams', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods')),
    ('Baguette', 'each', (SELECT vendorID FROM Vendors WHERE vendorName = 'Florence Bread Company')),
    ('Butter', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods')),
    ('Garlic', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods')),
    ('Hoagie roll', 'each', (SELECT vendorID FROM Vendors WHERE vendorName = 'Florence Bread Company')),
    ('Roast Beef', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco')),
    ('Havarti', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco')),
    ('Au jus', 'oz', (SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'));

INSERT INTO MenuItemIngredients (menuItemID, ingredientID, ingredientAmount) VALUES
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Forager Burger'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Bun'), 1.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Forager Burger'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Beef Patty'), 5.33),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Forager Burger'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Mushrooms'), 2.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Forager Burger'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Onions'), 2.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Forager Burger'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Smoked Gouda'), 0.75),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Forager Burger'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Lettuce'), 1.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Forager Burger'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Tomato'), 2.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Forager Burger'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Aioli'), 2.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Forager Burger'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'French Fries'), 8.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Cod Fish & Chips'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Cod'), 8.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Cod Fish & Chips'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Coleslaw mix'), 4.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Cod Fish & Chips'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Coleslaw dressing'), 2.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Cod Fish & Chips'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Tartar'), 2.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Cod Fish & Chips'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Rice Panko'), 2.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Cod Fish & Chips'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Rice Flour'), 1.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Cod Fish & Chips'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Egg'), 0.25),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Siltcoos Salad'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Mixed Greens'), 4.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Siltcoos Salad'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Hazelnuts'), 2.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Siltcoos Salad'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Pepitas'), 2.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Siltcoos Salad'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Cranberries'), 2.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Siltcoos Salad'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Blue Cheese'), 1.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Siltcoos Salad'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Salad Dressing'), 3.25),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Steamer Clams'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Clams'), 16.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Steamer Clams'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Baguette'), 0.25),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Steamer Clams'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Butter'), 2.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'Steamer Clams'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Garlic'), 0.50),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'French Dip'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Hoagie roll'), 1.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'French Dip'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Roast Beef'), 6.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'French Dip'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Havarti'), 0.75),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'French Dip'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Aioli'), 2.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'French Dip'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Au jus'), 3.00),
    ((SELECT menuItemID FROM MenuItems WHERE menuItemName = 'French Dip'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'French Fries'), 8.00);

INSERT INTO VendorIngredients (vendorID, ingredientID, unitCost) VALUES
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Bun'), 0.75),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Beef Patty'), 0.53),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Mushrooms'), 0.31),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Onions'), 0.25),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Smoked Gouda'), 0.44),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Lettuce'), 0.15),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Tomato'), 0.15),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Aioli'), 0.15),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'French Fries'), 0.16),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Cod'), 0.63),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Coleslaw mix'), 0.09),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Coleslaw dressing'), 0.10),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Tartar'), 0.15),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Rice Panko'), 0.20),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Rice Flour'), 0.12),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Egg'), 0.18),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Mixed Greens'), 0.20),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Hazelnuts'), 0.81),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Pepitas'), 0.32),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Cranberries'), 0.37),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Blue Cheese'), 0.56),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Clams'), 0.28),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Baguette'), 3.00),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Butter'), 0.19),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Garlic'), 0.50),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Hoagie roll'), 1.25),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Roast Beef'), 0.44),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Havarti'), 0.50),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'US Foods'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Au jus'), 0.20),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Bun'), 0.80),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Beef Patty'), 0.56),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Mushrooms'), 0.29),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Onions'), 0.33),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Smoked Gouda'), 0.42),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Lettuce'), 0.14),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Tomato'), 0.16),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Aioli'), 0.17),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'French Fries'), 0.14),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Cod'), 0.67),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Coleslaw mix'), 0.10),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Tartar'), 0.16),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Rice Panko'), 0.41),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Rice Flour'), 0.14),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Egg'), 0.17),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Mixed Greens'), 0.18),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Hazelnuts'), 0.90),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Pepitas'), 0.35),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Cranberries'), 0.40),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Blue Cheese'), 0.51),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Clams'), 0.35),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Baguette'), 3.25),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Butter'), 0.20),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Garlic'), 0.60),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Hoagie roll'), 1.40),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Roast Beef'), 0.42),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Havarti'), 0.48),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Sysco'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Au jus'), 0.25),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Florence Bread Company'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Bun'), 1.00),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Florence Bread Company'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Baguette'), 2.75),
    ((SELECT vendorID FROM Vendors WHERE vendorName = 'Florence Bread Company'),
     (SELECT ingredientID FROM Ingredients WHERE ingredientName = 'Hoagie roll'), 1.10);

SET FOREIGN_KEY_CHECKS = 1;

END //
DELIMITER ;

-- to load/reset the database:
-- CALL sp_load_foodmenudb();
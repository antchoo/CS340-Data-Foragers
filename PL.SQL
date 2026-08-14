-- The Data Foragers
-- Group 41 CS340 Summer 2026 OSU
-- Anton Choo and Borislava Grigorova
--
-- PL.SQL: Procedure Language SQL for the CS340 Portfolio Project (Final Step).
--
-- Every CREATE / UPDATE / DELETE operation exposed by the web app is
-- implemented as a stored procedure in this file, and webapp/app.js calls
-- them with `CALL sp_...(?);` (never inline DML). The plain-SQL versions of
-- these queries are listed in DML.sql for reference.
--
-- The RESET DB procedure, sp_load_foodmenudb(), is defined in DDL.sql because
-- it wraps the entire Data Definition Queries + sample data (following the
-- sp_moviedb.sql example from class). The thin sp_reset_foodmenudb() wrapper
-- at the bottom of this file is what the web app's RESET button calls, so all
-- four required operation types (CREATE, UPDATE, DELETE, RESET DB) are
-- reachable from this file. Import DDL.sql first, then this file.
--
-- Citation: procedure structure (DROP/DELIMITER/CREATE PROCEDURE pattern)
-- based on the CS340 PL/SQL course materials (sp_moviedb.sql example),
-- accessed 2026-08-12. AI use: procedures drafted with Claude
-- on 2026-08-10; prompt summary: "wrap our existing DML.sql insert/update/
-- delete queries for each entity into MySQL stored procedures". The
-- underlying queries and schema are our own work; each generated procedure
-- was reviewed and tested by the team.

-- ---------------------------------------------------------------
-- MenuItems entity
-- ---------------------------------------------------------------

-- CREATE: add a new menu item (total cost starts NULL until it has
-- ingredients and its cost is recalculated)
DROP PROCEDURE IF EXISTS sp_insert_menu_item;
DELIMITER //
CREATE PROCEDURE sp_insert_menu_item(
    IN p_menuItemName VARCHAR(155)
)
BEGIN
    INSERT INTO MenuItems (menuItemName)
    VALUES (p_menuItemName);
END //
DELIMITER ;

-- UPDATE: rename a menu item
DROP PROCEDURE IF EXISTS sp_update_menu_item;
DELIMITER //
CREATE PROCEDURE sp_update_menu_item(
    IN p_menuItemID INT,
    IN p_menuItemName VARCHAR(155)
)
BEGIN
    UPDATE MenuItems
    SET menuItemName = p_menuItemName
    WHERE menuItemID = p_menuItemID;
END //
DELIMITER ;

-- UPDATE: recalculate a menu item's total cost from its ingredient amounts
-- and each ingredient's preferred vendor's unit cost (ingredients with no
-- preferred vendor are excluded from the sum)
DROP PROCEDURE IF EXISTS sp_refresh_menu_item_cost;
DELIMITER //
CREATE PROCEDURE sp_refresh_menu_item_cost(
    IN p_menuItemID INT
)
BEGIN
    UPDATE MenuItems
    SET menuItemTotalCost = (
        SELECT SUM(MenuItemIngredients.ingredientAmount * VendorIngredients.unitCost)
        FROM MenuItemIngredients
        INNER JOIN Ingredients
            ON MenuItemIngredients.ingredientID = Ingredients.ingredientID
        INNER JOIN VendorIngredients
            ON Ingredients.ingredientID = VendorIngredients.ingredientID
            AND Ingredients.preferredVendorID = VendorIngredients.vendorID
        WHERE MenuItemIngredients.menuItemID = p_menuItemID
    )
    WHERE menuItemID = p_menuItemID;
END //
DELIMITER ;

-- DELETE: remove a menu item; its MenuItemIngredients rows are removed
-- automatically by ON DELETE CASCADE (no orphaned intersection rows)
DROP PROCEDURE IF EXISTS sp_delete_menu_item;
DELIMITER //
CREATE PROCEDURE sp_delete_menu_item(
    IN p_menuItemID INT
)
BEGIN
    DELETE FROM MenuItems
    WHERE menuItemID = p_menuItemID;
END //
DELIMITER ;

-- ---------------------------------------------------------------
-- Ingredients entity
-- ---------------------------------------------------------------

-- CREATE: add a new ingredient; p_preferredVendorID is nullable (an
-- ingredient may have no preferred vendor yet)
DROP PROCEDURE IF EXISTS sp_insert_ingredient;
DELIMITER //
CREATE PROCEDURE sp_insert_ingredient(
    IN p_ingredientName VARCHAR(155),
    IN p_unitType VARCHAR(4),
    IN p_preferredVendorID INT
)
BEGIN
    INSERT INTO Ingredients (ingredientName, unitType, preferredVendorID)
    VALUES (p_ingredientName, p_unitType, p_preferredVendorID);
END //
DELIMITER ;

-- UPDATE: change an ingredient's preferred vendor (NULLable FK; passing NULL
-- clears the preferred vendor)
DROP PROCEDURE IF EXISTS sp_update_ingredient_vendor;
DELIMITER //
CREATE PROCEDURE sp_update_ingredient_vendor(
    IN p_ingredientID INT,
    IN p_preferredVendorID INT
)
BEGIN
    UPDATE Ingredients
    SET preferredVendorID = p_preferredVendorID
    WHERE ingredientID = p_ingredientID;
END //
DELIMITER ;

-- DELETE: remove an ingredient; its rows in both intersection tables are
-- removed automatically by ON DELETE CASCADE
DROP PROCEDURE IF EXISTS sp_delete_ingredient;
DELIMITER //
CREATE PROCEDURE sp_delete_ingredient(
    IN p_ingredientID INT
)
BEGIN
    DELETE FROM Ingredients
    WHERE ingredientID = p_ingredientID;
END //
DELIMITER ;

-- ---------------------------------------------------------------
-- Vendors entity
-- ---------------------------------------------------------------

-- CREATE: add a new vendor
DROP PROCEDURE IF EXISTS sp_insert_vendor;
DELIMITER //
CREATE PROCEDURE sp_insert_vendor(
    IN p_vendorName VARCHAR(155),
    IN p_vendorRepresentative VARCHAR(155),
    IN p_vendorContact VARCHAR(13)
)
BEGIN
    INSERT INTO Vendors (vendorName, vendorRepresentative, vendorContact)
    VALUES (p_vendorName, p_vendorRepresentative, p_vendorContact);
END //
DELIMITER ;

-- UPDATE: change a vendor's name, representative, and contact number
DROP PROCEDURE IF EXISTS sp_update_vendor;
DELIMITER //
CREATE PROCEDURE sp_update_vendor(
    IN p_vendorID INT,
    IN p_vendorName VARCHAR(155),
    IN p_vendorRepresentative VARCHAR(155),
    IN p_vendorContact VARCHAR(13)
)
BEGIN
    UPDATE Vendors
    SET vendorName = p_vendorName,
        vendorRepresentative = p_vendorRepresentative,
        vendorContact = p_vendorContact
    WHERE vendorID = p_vendorID;
END //
DELIMITER ;

-- DELETE: remove a vendor; its VendorIngredients rows are removed by
-- ON DELETE CASCADE, and Ingredients.preferredVendorID is set NULL by
-- ON DELETE SET NULL (ingredients themselves are kept)
DROP PROCEDURE IF EXISTS sp_delete_vendor;
DELIMITER //
CREATE PROCEDURE sp_delete_vendor(
    IN p_vendorID INT
)
BEGIN
    DELETE FROM Vendors
    WHERE vendorID = p_vendorID;
END //
DELIMITER ;

-- ---------------------------------------------------------------
-- MenuItemIngredients (M:N intersection of MenuItems and Ingredients)
-- ---------------------------------------------------------------

-- CREATE (M:N): relate an ingredient to a menu item with an amount
DROP PROCEDURE IF EXISTS sp_insert_menu_item_ingredient;
DELIMITER //
CREATE PROCEDURE sp_insert_menu_item_ingredient(
    IN p_menuItemID INT,
    IN p_ingredientID INT,
    IN p_ingredientAmount DECIMAL(4,2)
)
BEGIN
    INSERT INTO MenuItemIngredients (menuItemID, ingredientID, ingredientAmount)
    VALUES (p_menuItemID, p_ingredientID, p_ingredientAmount);
END //
DELIMITER ;

-- UPDATE (M:N): update a MenuItemIngredients row INCLUDING both FK values,
-- satisfying the "update an M:N relationship" requirement
DROP PROCEDURE IF EXISTS sp_update_menu_item_ingredient;
DELIMITER //
CREATE PROCEDURE sp_update_menu_item_ingredient(
    IN p_menuItemIngredientID INT,
    IN p_menuItemID INT,
    IN p_ingredientID INT,
    IN p_ingredientAmount DECIMAL(4,2)
)
BEGIN
    UPDATE MenuItemIngredients
    SET menuItemID = p_menuItemID,
        ingredientID = p_ingredientID,
        ingredientAmount = p_ingredientAmount
    WHERE menuItemIngredientID = p_menuItemIngredientID;
END //
DELIMITER ;

-- DELETE (M:N): remove one menu item / ingredient pairing, satisfying the
-- "delete an M:N relationship" requirement (deletes only the intersection
-- row; both related entities are untouched, so no data anomaly)
DROP PROCEDURE IF EXISTS sp_delete_menu_item_ingredient;
DELIMITER //
CREATE PROCEDURE sp_delete_menu_item_ingredient(
    IN p_menuItemIngredientID INT
)
BEGIN
    DELETE FROM MenuItemIngredients
    WHERE menuItemIngredientID = p_menuItemIngredientID;
END //
DELIMITER ;

-- ---------------------------------------------------------------
-- VendorIngredients (M:N intersection of Vendors and Ingredients)
-- ---------------------------------------------------------------

-- CREATE (M:N): relate an ingredient to a vendor with a unit cost
DROP PROCEDURE IF EXISTS sp_insert_vendor_ingredient;
DELIMITER //
CREATE PROCEDURE sp_insert_vendor_ingredient(
    IN p_vendorID INT,
    IN p_ingredientID INT,
    IN p_unitCost DECIMAL(4,2)
)
BEGIN
    INSERT INTO VendorIngredients (vendorID, ingredientID, unitCost)
    VALUES (p_vendorID, p_ingredientID, p_unitCost);
END //
DELIMITER ;

-- UPDATE (M:N): update a VendorIngredients row INCLUDING both FK values
DROP PROCEDURE IF EXISTS sp_update_vendor_ingredient;
DELIMITER //
CREATE PROCEDURE sp_update_vendor_ingredient(
    IN p_vendorIngredientID INT,
    IN p_vendorID INT,
    IN p_ingredientID INT,
    IN p_unitCost DECIMAL(4,2)
)
BEGIN
    UPDATE VendorIngredients
    SET vendorID = p_vendorID,
        ingredientID = p_ingredientID,
        unitCost = p_unitCost
    WHERE vendorIngredientID = p_vendorIngredientID;
END //
DELIMITER ;

-- DELETE (M:N): remove one vendor / ingredient offering
DROP PROCEDURE IF EXISTS sp_delete_vendor_ingredient;
DELIMITER //
CREATE PROCEDURE sp_delete_vendor_ingredient(
    IN p_vendorIngredientID INT
)
BEGIN
    DELETE FROM VendorIngredients
    WHERE vendorIngredientID = p_vendorIngredientID;
END //
DELIMITER ;

-- ---------------------------------------------------------------
-- RESET DB
-- ---------------------------------------------------------------

-- RESET: restore every table to its original state as defined in DDL.sql.
-- The heavy lifting (DROP/CREATE/INSERT of all five tables) lives in
-- sp_load_foodmenudb() in DDL.sql, which must be imported before this file.
-- This wrapper is what POST /reset in webapp/app.js calls.
DROP PROCEDURE IF EXISTS sp_reset_foodmenudb;
DELIMITER //
CREATE PROCEDURE sp_reset_foodmenudb()
BEGIN
    CALL sp_load_foodmenudb();
END //
DELIMITER ;

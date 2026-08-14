-- The Data Foragers
-- Group 41 CS340 Summer 2026 OSU
-- Anton Choo and Borislava Grigorova
--
-- DML.sql: Data Manipulation Queries for the CS340 Portfolio Project
-- (Final Step). These queries are the ones executed by webapp/app.js.
--
-- '@' denotes a value supplied by the user through the web UI (form field,
-- dropdown selection, or per-row button) and passed as a parameter by the
-- backend. SELECTs run inline in app.js; every INSERT / UPDATE / DELETE runs
-- inside the matching stored procedure in PL.SQL (named after each query
-- below), so the app only ever issues CALL statements for CUD.

-- ===============================================================
-- MenuItems entity
-- ===============================================================

-- display all Menu Items (Menu Items page, browse table)
SELECT menuItemID, menuItemName, menuItemTotalCost
FROM MenuItems
ORDER BY menuItemName;

-- populate the Menu Item dropdowns (Menu Items + Menu Item Ingredients pages)
SELECT menuItemID, menuItemName FROM MenuItems ORDER BY menuItemName;

-- create a new Menu Item (run by sp_insert_menu_item)
INSERT INTO MenuItems (menuItemName)
VALUES (@menuItemName);

-- update a Menu Item's name (run by sp_update_menu_item)
UPDATE MenuItems
SET menuItemName = @menuItemName
WHERE menuItemID = @menuItemID;

-- recalculate a Menu Item's total cost from its ingredient amounts and each
-- ingredient's preferred vendor's unit cost (run by sp_refresh_menu_item_cost)
UPDATE MenuItems
SET menuItemTotalCost = (
    SELECT SUM(MenuItemIngredients.ingredientAmount * VendorIngredients.unitCost)
    FROM MenuItemIngredients
    INNER JOIN Ingredients
        ON MenuItemIngredients.ingredientID = Ingredients.ingredientID
    INNER JOIN VendorIngredients
        ON Ingredients.ingredientID = VendorIngredients.ingredientID
        AND Ingredients.preferredVendorID = VendorIngredients.vendorID
    WHERE MenuItemIngredients.menuItemID = @menuItemID
)
WHERE menuItemID = @menuItemID;

-- delete a Menu Item (run by sp_delete_menu_item; ON DELETE CASCADE removes
-- its MenuItemIngredients rows)
DELETE FROM MenuItems
WHERE menuItemID = @menuItemID;

-- ===============================================================
-- Ingredients entity
-- ===============================================================

-- display all ingredients, showing the preferred vendor's name instead of
-- its ID (Ingredients page, browse table)
SELECT Ingredients.ingredientID, Ingredients.ingredientName, Ingredients.unitType,
       Vendors.vendorName AS preferredVendor
FROM Ingredients
LEFT JOIN Vendors ON Ingredients.preferredVendorID = Vendors.vendorID
ORDER BY Ingredients.ingredientName;

-- populate the Ingredient dropdowns (Ingredients + both intersection pages)
SELECT ingredientID, ingredientName, unitType FROM Ingredients ORDER BY ingredientName;

-- add an ingredient; @preferredVendorID is NULL when "(none yet)" is chosen
-- (run by sp_insert_ingredient)
INSERT INTO Ingredients (ingredientName, unitType, preferredVendorID)
VALUES (@ingredientName, @unitType, @preferredVendorID);

-- update the preferred vendor for an ingredient; NULL clears it
-- (run by sp_update_ingredient_vendor)
UPDATE Ingredients
SET preferredVendorID = @preferredVendorID
WHERE ingredientID = @ingredientID;

-- delete an ingredient (run by sp_delete_ingredient; ON DELETE CASCADE
-- removes its rows in both intersection tables)
DELETE FROM Ingredients
WHERE ingredientID = @ingredientID;

-- ===============================================================
-- Vendors entity
-- ===============================================================

-- display all vendors (Vendors page, browse table)
SELECT vendorID, vendorName, vendorRepresentative, vendorContact
FROM Vendors
ORDER BY vendorName;

-- populate the Vendor dropdowns (Ingredients + Vendor Ingredients pages)
SELECT vendorID, vendorName FROM Vendors ORDER BY vendorName;

-- add a new vendor (run by sp_insert_vendor)
INSERT INTO Vendors (vendorName, vendorRepresentative, vendorContact)
VALUES (@vendorName, @vendorRepresentative, @vendorContact);

-- update vendor information (run by sp_update_vendor)
UPDATE Vendors
SET vendorName = @vendorName,
    vendorRepresentative = @vendorRepresentative,
    vendorContact = @vendorContact
WHERE vendorID = @vendorID;

-- delete a vendor (run by sp_delete_vendor; VendorIngredients rows are
-- CASCADE-deleted and Ingredients.preferredVendorID is SET NULL)
DELETE FROM Vendors
WHERE vendorID = @vendorID;

-- ===============================================================
-- MenuItemIngredients (M:N intersection of MenuItems and Ingredients)
-- ===============================================================

-- display all menu item / ingredient pairings with names instead of IDs
-- (Menu Item Ingredients page, browse table)
SELECT MenuItemIngredients.menuItemIngredientID,
       MenuItems.menuItemName,
       Ingredients.ingredientName,
       MenuItemIngredients.ingredientAmount,
       Ingredients.unitType
FROM MenuItemIngredients
INNER JOIN MenuItems ON MenuItemIngredients.menuItemID = MenuItems.menuItemID
INNER JOIN Ingredients ON MenuItemIngredients.ingredientID = Ingredients.ingredientID
ORDER BY MenuItems.menuItemName, Ingredients.ingredientName;

-- add an ingredient to a menu item -- M:N insert
-- (run by sp_insert_menu_item_ingredient)
INSERT INTO MenuItemIngredients (menuItemID, ingredientID, ingredientAmount)
VALUES (@menuItemID, @ingredientID, @ingredientAmount);

-- update a menu item / ingredient pairing, including BOTH foreign keys --
-- M:N relationship update (run by sp_update_menu_item_ingredient)
UPDATE MenuItemIngredients
SET menuItemID = @menuItemID,
    ingredientID = @ingredientID,
    ingredientAmount = @ingredientAmount
WHERE menuItemIngredientID = @menuItemIngredientID;

-- remove an ingredient from a menu item -- M:N relationship delete
-- (run by sp_delete_menu_item_ingredient)
DELETE FROM MenuItemIngredients
WHERE menuItemIngredientID = @menuItemIngredientID;

-- ===============================================================
-- VendorIngredients (M:N intersection of Vendors and Ingredients)
-- ===============================================================

-- display all vendor / ingredient offerings with names instead of IDs
-- (Vendor Ingredients page, browse table)
SELECT VendorIngredients.vendorIngredientID,
       Vendors.vendorName,
       Ingredients.ingredientName,
       VendorIngredients.unitCost,
       Ingredients.unitType
FROM VendorIngredients
INNER JOIN Vendors ON VendorIngredients.vendorID = Vendors.vendorID
INNER JOIN Ingredients ON VendorIngredients.ingredientID = Ingredients.ingredientID
ORDER BY Vendors.vendorName, Ingredients.ingredientName;

-- add an ingredient to a vendor -- M:N insert
-- (run by sp_insert_vendor_ingredient)
INSERT INTO VendorIngredients (vendorID, ingredientID, unitCost)
VALUES (@vendorID, @ingredientID, @unitCost);

-- update a vendor / ingredient offering, including BOTH foreign keys --
-- M:N relationship update (run by sp_update_vendor_ingredient)
UPDATE VendorIngredients
SET vendorID = @vendorID,
    ingredientID = @ingredientID,
    unitCost = @unitCost
WHERE vendorIngredientID = @vendorIngredientID;

-- remove an ingredient from a vendor -- M:N relationship delete
-- (run by sp_delete_vendor_ingredient)
DELETE FROM VendorIngredients
WHERE vendorIngredientID = @vendorIngredientID;

-- ===============================================================
-- RESET DB
-- ===============================================================

-- restore every table to its original state as defined in DDL.sql
-- (RESET Database button; sp_reset_foodmenudb in PL.SQL wraps
-- sp_load_foodmenudb in DDL.sql)
CALL sp_reset_foodmenudb();

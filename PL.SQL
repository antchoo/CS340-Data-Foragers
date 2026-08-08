-- The Data Foragers
-- Group 41 CS340 Summer 2026 OSU
-- Anton Choo and Borislava Grigorova
--
-- PL.SQL: Procedure Language SQL for Step 4.
--
-- Step 4 requires only ONE working CUD operation, 

-- this is used to demonstrate that the RESET button works.
-- Ours is the hard-coded DELETE below, which removes
-- the 'French Dip' menu item. The general-purpose parameterized version of
-- this query stays in DML.sql ("delete a menu item") for reference and will
-- be implemented as part of full CRUD in the next project step.
--
-- The RESET procedure itself, sp_load_foodmenudb(), lives in DDL.sql since it
-- wraps the Data Definition Queries (per the sp_moviedb.sql example).
--

DROP PROCEDURE IF EXISTS sp_demo_delete_menu_item;

DELIMITER //
CREATE PROCEDURE sp_demo_delete_menu_item()
BEGIN
    -- hard-coded demo delete; MenuItemIngredients rows for this item (if any)
    -- are removed automatically by ON DELETE CASCADE
    DELETE FROM MenuItems WHERE menuItemName = 'French Dip';
END //
DELIMITER ;

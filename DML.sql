-- The Data Foragers
-- Group 41 CS340 Summer 2026 OSU
-- Anton Choo and Borislava Grigorova

-- '@' symbol denotes a user input variable which will be implemented in the next project step.
-- ':' symbol denotes a variable, which will be retrieved from the backend programming language,
-- and will be implemented in the next project step.

-- functionality for menuItems entity
-- display all Menu Items
SELECT
    menuItemID,
    menuItemName,
    menuItemTotalCost
FROM
    MenuItems;

-- create a new Menu Item
INSERT INTO MenuItems (
    menuItemName
    )
VALUES (
    @menuItemName
);

-- update a Menu Item
UPDATE
    MenuItems
SET menuItemName = @menuItemName
WHERE
    menuItemId = @menuItemID;

-- delete a Menu Item
DELETE FROM
    MenuItems
WHERE
    menuItemID = @menuItemID;

-- calculate a Menu Item's Total Cost
SELECT
    MenuItems.menuItemID,
    MenuItems.menuItemName,
SUM(MenuItemIngredients.ingredientAmount * VendorIngredients.unitCost)
    AS menuItemTotalCost
FROM
    MenuItems
INNER JOIN MenuItemIngredients
    ON MenuItems.menuItemID = MenuItemIngredients.menuItemID
INNER JOIN Ingredients
    ON MenuItemIngredients.ingredientID = Ingredients.ingredientID
INNER JOIN VendorIngredients
    ON Ingredients.ingredientID = VendorIngredients.ingredientID
    AND Ingredients.preferredVendorID = VendorIngredients.vendorID
WHERE
    MenuItems.menuItemID = @menuItemID
GROUP BY
    MenuItems.menuItemID,
    MenuItems.menuItemName;

-- functionality for Ingredients entity
-- display all ingredients
SELECT
    ingredientID,
    ingredientName,
    unitType,
    preferredVendorID
FROM
    Ingredients;

-- add an ingredient
INSERT INTO Ingredients (
    ingredientName,
    unitType
)
VALUES (
    @ingredientName,
    @unitType
);

-- update the preferred vendor for an ingredient
UPDATE
    Ingredients
SET preferredVendorID = @preferredVendorID
WHERE
    ingredientID = @ingredientID;

-- delete an ingredient
DELETE FROM
    Ingredients
WHERE
    ingredientID = @ingredientID;

-- functionality for the Vendors entity
-- display all vendors
SELECT
    vendorID,
    vendorName,
    vendorRepresentative,
    vendorContact
FROM
    Vendors;

-- add a new vendor
INSERT INTO Vendors (
    vendorName,
    vendorRepresentative,
    vendorContact
)
VALUES (
    @vendorName,
    @vendorRepresentative,
    @vendorContact
);

-- update vendor information
UPDATE
    Vendors
SET
    vendorRepresentative = @vendorRepresentative,
    vendorContact = @vendorContact
WHERE
    vendorID = @vendorID;

-- delete a vendor
DELETE FROM
    Vendors
WHERE
    vendorID = @vendorID;

-- functionality for MenuItemIngredients entity
-- display all menu item ingredients
SELECT
    MenuItemIngredients.menuItemIngredientID,
    MenuItems.menuItemName,
    Ingredients.ingredientName,
    ingredientAmount
FROM
    MenuItemIngredients
INNER JOIN MenuItems
    ON MenuItemIngredients.menuItemID = MenuItems.menuItemID
INNER JOIN Ingredients
    ON MenuItemIngredients.ingredientID = Ingredients.ingredientID;

-- add an ingredient to a menu item
INSERT INTO MenuItemIngredients (
    menuItemID,
    ingredientID,
    ingredientAmount
)
VALUES (
    @menuItemID,
    @ingredientID,
    @ingredientAmount
);

-- remove an ingredient from a menu item
DELETE FROM
    MenuItemIngredients
WHERE
    menuItemIngredientID = @menuItemIngredientID;

-- functionality for the VendorIngredients entity
-- display all vendor ingredients
SELECT
    VendorIngredients.vendorIngredientID,
    Vendors.vendorName,
    Ingredients.ingredientName,
    VendorIngredients.unitCost
FROM
    VendorIngredients
INNER JOIN Vendors
    ON VendorIngredients.vendorID = Vendors.vendorID
INNER JOIN Ingredients
    ON VendorIngredients.ingredientID = Ingredients.ingredientID;

-- add an ingredient to a vendor
INSERT INTO VendorIngredients (
    vendorID,
    ingredientID,
    unitCost
)
VALUES (
    @vendorID,
    @ingredientID,
    @unitCost
);

-- update the cost of an ingredient
UPDATE
    VendorIngredients
SET unitCost = @unitCost
WHERE vendorIngredientID = @vendorIngredientID;

-- remove an ingredient from a vendor
DELETE FROM
    VendorIngredients
WHERE vendorIngredientID = @vendorIngredientID;
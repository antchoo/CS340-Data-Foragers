/*
    The Data Foragers - Group 41 CS340 Summer 2026 OSU
    Anton Choo and Borislava Grigorova

    Step 4 Draft: serves the UI pages for the Homegrown Restaurant Food Menu
    Pricing System. Every entity page now runs its SELECT queries from DML.sql
    against the database. The RESET button and the "delete French Dip" demo
    call the stored procedures defined in DDL.sql / PL.SQL.

    Only the RESET and its demo DELETE are functional CUD operations in this
    step; the add/update/delete forms on the entity pages are wired to stub
    routes and will be implemented in the next project step.
*/

const express = require('express');
const { engine } = require('express-handlebars');
const db = require('./database/db-connector');

const app = express();
const PORT = process.env.PORT || 46231; // assigned port on the ENGR server

// handlebars setup
app.engine('.hbs', engine({ extname: '.hbs' }));
app.set('view engine', '.hbs');
app.set('views', './views');

app.use(express.urlencoded({ extended: true }));
app.use(express.json());

/*
    Each GET route below runs the matching SELECT from DML.sql (the query text
    is copied verbatim; the DML.sql comment naming it is noted above each one).
    If the database is unreachable the page still renders with an error banner
    so the UI stays browsable.
*/

// home page
app.get('/', (req, res) => {
    res.render('index');
});

// MenuItems page -- DML.sql: "browse all menu items"
app.get('/menuItems', async (req, res) => {
    try {
        const [menuItems] = await db.query(
            `SELECT menuItemID, menuItemName, menuItemTotalCost
             FROM MenuItems
             ORDER BY menuItemName;`
        );
        res.render('menuItems', { menuItems: menuItems });
    } catch (error) {
        console.error('Error loading /menuItems:', error);
        res.render('menuItems', { menuItems: [], dbError: error.message });
    }
});

// Ingredients page -- DML.sql: "browse all ingredients, showing the preferred
// vendor's name instead of its ID" + "populate the Preferred Vendor dropdown"
app.get('/ingredients', async (req, res) => {
    try {
        const [ingredients] = await db.query(
            `SELECT Ingredients.ingredientID, Ingredients.ingredientName, Ingredients.unitType,
                    Vendors.vendorName AS preferredVendor
             FROM Ingredients
             LEFT JOIN Vendors ON Ingredients.preferredVendorID = Vendors.vendorID
             ORDER BY Ingredients.ingredientName;`
        );
        const [vendors] = await db.query(
            `SELECT vendorID, vendorName FROM Vendors ORDER BY vendorName;`
        );
        res.render('ingredients', { ingredients: ingredients, vendors: vendors });
    } catch (error) {
        console.error('Error loading /ingredients:', error);
        res.render('ingredients', { ingredients: [], vendors: [], dbError: error.message });
    }
});

// Vendors page -- DML.sql: "browse all vendors"
app.get('/vendors', async (req, res) => {
    try {
        const [vendors] = await db.query(
            `SELECT vendorID, vendorName, vendorRepresentative, vendorContact
             FROM Vendors
             ORDER BY vendorName;`
        );
        res.render('vendors', { vendors: vendors });
    } catch (error) {
        console.error('Error loading /vendors:', error);
        res.render('vendors', { vendors: [], dbError: error.message });
    }
});

// MenuItemIngredients page -- DML.sql: "browse all menu item / ingredient
// pairings" + the Menu Item and Ingredient dropdown queries
app.get('/menuItemIngredients', async (req, res) => {
    try {
        const [menuItemIngredients] = await db.query(
            `SELECT MenuItemIngredients.menuItemIngredientID,
                    MenuItems.menuItemName,
                    Ingredients.ingredientName,
                    MenuItemIngredients.ingredientAmount,
                    Ingredients.unitType
             FROM MenuItemIngredients
             INNER JOIN MenuItems ON MenuItemIngredients.menuItemID = MenuItems.menuItemID
             INNER JOIN Ingredients ON MenuItemIngredients.ingredientID = Ingredients.ingredientID
             ORDER BY MenuItems.menuItemName, Ingredients.ingredientName;`
        );
        const [menuItems] = await db.query(
            `SELECT menuItemID, menuItemName FROM MenuItems ORDER BY menuItemName;`
        );
        const [ingredients] = await db.query(
            `SELECT ingredientID, ingredientName FROM Ingredients ORDER BY ingredientName;`
        );
        res.render('menuItemIngredients', {
            menuItemIngredients: menuItemIngredients,
            menuItems: menuItems,
            ingredients: ingredients
        });
    } catch (error) {
        console.error('Error loading /menuItemIngredients:', error);
        res.render('menuItemIngredients', {
            menuItemIngredients: [], menuItems: [], ingredients: [], dbError: error.message
        });
    }
});

// VendorIngredients page -- DML.sql: "browse all vendor / ingredient
// offerings" + the Vendor and Ingredient dropdown queries
app.get('/vendorIngredients', async (req, res) => {
    try {
        const [vendorIngredients] = await db.query(
            `SELECT VendorIngredients.vendorIngredientID,
                    Vendors.vendorName,
                    Ingredients.ingredientName,
                    VendorIngredients.unitCost,
                    Ingredients.unitType
             FROM VendorIngredients
             INNER JOIN Vendors ON VendorIngredients.vendorID = Vendors.vendorID
             INNER JOIN Ingredients ON VendorIngredients.ingredientID = Ingredients.ingredientID
             ORDER BY Vendors.vendorName, Ingredients.ingredientName;`
        );
        const [vendors] = await db.query(
            `SELECT vendorID, vendorName FROM Vendors ORDER BY vendorName;`
        );
        const [ingredients] = await db.query(
            `SELECT ingredientID, ingredientName FROM Ingredients ORDER BY ingredientName;`
        );
        res.render('vendorIngredients', {
            vendorIngredients: vendorIngredients,
            vendors: vendors,
            ingredients: ingredients
        });
    } catch (error) {
        console.error('Error loading /vendorIngredients:', error);
        res.render('vendorIngredients', {
            vendorIngredients: [], vendors: [], ingredients: [], dbError: error.message
        });
    }
});

/*
    RESET button: drops and recreates the whole schema with its sample data by
    calling the stored procedure that wraps DDL.sql (see DDL.sql / PL.SQL --
    the procedure name must stay in sync with those files).
*/
app.post('/reset', async (req, res) => {
    try {
        await db.query('CALL sp_load_foodmenudb();');
        res.redirect('/menuItems');
    } catch (error) {
        console.error('Error executing sp_load_foodmenudb:', error);
        res.status(500).send('An error occurred while resetting the database.');
    }
});

/*
    Demo CUD operation to show that RESET works: deletes the 'French Dip' menu
    item via a stored procedure (see PL.SQL). Visit /menuItems, use this
    button, watch French Dip disappear, then press RESET to bring it back.
*/
app.post('/menuItems/delete-french-dip', async (req, res) => {
    try {
        await db.query('CALL sp_demo_delete_menu_item();');
        res.redirect('/menuItems');
    } catch (error) {
        console.error('Error executing sp_demo_delete_menu_item:', error);
        res.status(500).send('An error occurred while running the demo delete.');
    }
});

/*
    The add/update/delete forms on the entity pages post to these routes.
    They are intentionally stubs for Step 4 (only one CUD operation is
    required, the RESET demo above); they will call the DML.sql queries via
    PL/SQL in the next project step.
*/
const notImplemented = (req, res) => {
    res.status(501).send(
        'This add/update/delete operation will be implemented in the next ' +
        'project step. <a href="javascript:history.back()">Go back</a>'
    );
};

[
    '/menuItems/add', '/menuItems/update', '/menuItems/delete', '/menuItems/calculateTotalCost',
    '/ingredients/add', '/ingredients/update', '/ingredients/delete',
    '/vendors/add', '/vendors/update', '/vendors/delete',
    '/menuItemIngredients/add', '/menuItemIngredients/update', '/menuItemIngredients/delete',
    '/vendorIngredients/add', '/vendorIngredients/update', '/vendorIngredients/delete'
].forEach((path) => app.post(path, notImplemented));

app.listen(PORT, () => {
    console.log(`Express started on http://localhost:${PORT}; press Ctrl-C to terminate.`);
});

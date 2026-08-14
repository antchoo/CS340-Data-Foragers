/*
    The Data Foragers - Group 41 CS340 Summer 2026 OSU
    Anton Choo and Borislava Grigorova

    CS340 Portfolio Project (Final Step): serves the UI for the Homegrown
    Restaurant Food Menu Pricing System.

    - Every entity page runs its SELECT queries (listed in DML.sql).
    - Every CREATE / UPDATE / DELETE goes through a stored procedure defined
      in PL.SQL (`CALL sp_...`); no inline INSERT/UPDATE/DELETE here.
    - The RESET button calls sp_reset_foodmenudb() (PL.SQL), which rebuilds
      the schema and sample data via sp_load_foodmenudb() (DDL.sql).

    Citation: Express + express-handlebars app structure and the
    route/render pattern adapted from the OSU CS340 nodejs-starter-app
    (https://github.com/osu-cs340-ecampus/nodejs-starter-app), accessed
    2026-08-06. All queries, stored-procedure calls, routes, and page logic
    below are our own work; CUD routes drafted with Claude (Anthropic) on
    2026-08-12 and reviewed by the team (see README.md).
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
    Helper for CUD routes: runs the stored-procedure call, then sends the
    user back to the page they came from. If the database rejects the
    operation the error is shown with a link back so the UI stays usable.
*/
async function runProcedure(res, redirectTo, sql, params, actionLabel) {
    try {
        await db.query(sql, params);
        res.redirect(redirectTo);
    } catch (error) {
        console.error(`Error during ${actionLabel}:`, error);
        res.status(500).send(
            `An error occurred while trying to ${actionLabel}: ${error.message}. ` +
            '<a href="javascript:history.back()">Go back</a>'
        );
    }
}

/*
    READ routes: each GET below runs the matching SELECT from DML.sql. If the
    database is unreachable the page still renders with an error banner so
    the UI stays browsable.
*/

// home page
app.get('/', (req, res) => {
    res.render('index');
});

// MenuItems page -- DML.sql: "display all Menu Items"
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

// Ingredients page -- DML.sql: "display all ingredients" (joined to Vendors
// so the preferred vendor's name is shown) + the Preferred Vendor dropdown
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

// Vendors page -- DML.sql: "display all vendors"
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

// MenuItemIngredients page -- DML.sql: "display all menu item ingredients"
// + the Menu Item and Ingredient dropdown queries
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
            `SELECT ingredientID, ingredientName, unitType FROM Ingredients ORDER BY ingredientName;`
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

// VendorIngredients page -- DML.sql: "display all vendor ingredients"
// + the Vendor and Ingredient dropdown queries
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
            `SELECT ingredientID, ingredientName, unitType FROM Ingredients ORDER BY ingredientName;`
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
    CUD routes: every operation below calls a stored procedure from PL.SQL.
*/

// MenuItems ------------------------------------------------------

app.post('/menuItems/add', (req, res) => {
    runProcedure(res, '/menuItems',
        'CALL sp_insert_menu_item(?);',
        [req.body.menuItemName],
        'add the menu item');
});

app.post('/menuItems/update', (req, res) => {
    runProcedure(res, '/menuItems',
        'CALL sp_update_menu_item(?, ?);',
        [req.body.menuItemID, req.body.menuItemName],
        'update the menu item');
});

app.post('/menuItems/delete', (req, res) => {
    runProcedure(res, '/menuItems',
        'CALL sp_delete_menu_item(?);',
        [req.body.menuItemID],
        'delete the menu item');
});

// recalculates menuItemTotalCost from ingredient amounts x the preferred
// vendor's unit cost (an UPDATE run inside sp_refresh_menu_item_cost)
app.post('/menuItems/calculateTotalCost', (req, res) => {
    runProcedure(res, '/menuItems',
        'CALL sp_refresh_menu_item_cost(?);',
        [req.body.menuItemID],
        "recalculate the menu item's total cost");
});

// Ingredients ----------------------------------------------------

app.post('/ingredients/add', (req, res) => {
    // the Preferred Vendor dropdown sends '' for "none"; store NULL then
    const preferredVendorID = req.body.preferredVendorID || null;
    runProcedure(res, '/ingredients',
        'CALL sp_insert_ingredient(?, ?, ?);',
        [req.body.ingredientName, req.body.unitType, preferredVendorID],
        'add the ingredient');
});

app.post('/ingredients/update', (req, res) => {
    const preferredVendorID = req.body.preferredVendorID || null;
    runProcedure(res, '/ingredients',
        'CALL sp_update_ingredient_vendor(?, ?);',
        [req.body.ingredientID, preferredVendorID],
        "update the ingredient's preferred vendor");
});

app.post('/ingredients/delete', (req, res) => {
    runProcedure(res, '/ingredients',
        'CALL sp_delete_ingredient(?);',
        [req.body.ingredientID],
        'delete the ingredient');
});

// Vendors --------------------------------------------------------

app.post('/vendors/add', (req, res) => {
    runProcedure(res, '/vendors',
        'CALL sp_insert_vendor(?, ?, ?);',
        [req.body.vendorName, req.body.vendorRepresentative || null, req.body.vendorContact || null],
        'add the vendor');
});

app.post('/vendors/update', (req, res) => {
    runProcedure(res, '/vendors',
        'CALL sp_update_vendor(?, ?, ?, ?);',
        [req.body.vendorID, req.body.vendorName,
         req.body.vendorRepresentative || null, req.body.vendorContact || null],
        'update the vendor');
});

app.post('/vendors/delete', (req, res) => {
    runProcedure(res, '/vendors',
        'CALL sp_delete_vendor(?);',
        [req.body.vendorID],
        'delete the vendor');
});

// MenuItemIngredients (M:N) --------------------------------------

app.post('/menuItemIngredients/add', (req, res) => {
    runProcedure(res, '/menuItemIngredients',
        'CALL sp_insert_menu_item_ingredient(?, ?, ?);',
        [req.body.menuItemID, req.body.ingredientID, req.body.ingredientAmount],
        'add the menu item ingredient');
});

// UPDATE of an M:N relationship: both FK values in the intersection row can
// be changed here
app.post('/menuItemIngredients/update', (req, res) => {
    runProcedure(res, '/menuItemIngredients',
        'CALL sp_update_menu_item_ingredient(?, ?, ?, ?);',
        [req.body.menuItemIngredientID, req.body.menuItemID,
         req.body.ingredientID, req.body.ingredientAmount],
        'update the menu item ingredient');
});

// DELETE of an M:N relationship: removes only the intersection row
app.post('/menuItemIngredients/delete', (req, res) => {
    runProcedure(res, '/menuItemIngredients',
        'CALL sp_delete_menu_item_ingredient(?);',
        [req.body.menuItemIngredientID],
        'delete the menu item ingredient');
});

// VendorIngredients (M:N) ----------------------------------------

app.post('/vendorIngredients/add', (req, res) => {
    runProcedure(res, '/vendorIngredients',
        'CALL sp_insert_vendor_ingredient(?, ?, ?);',
        [req.body.vendorID, req.body.ingredientID, req.body.unitCost],
        'add the vendor ingredient');
});

app.post('/vendorIngredients/update', (req, res) => {
    runProcedure(res, '/vendorIngredients',
        'CALL sp_update_vendor_ingredient(?, ?, ?, ?);',
        [req.body.vendorIngredientID, req.body.vendorID,
         req.body.ingredientID, req.body.unitCost],
        'update the vendor ingredient');
});

app.post('/vendorIngredients/delete', (req, res) => {
    runProcedure(res, '/vendorIngredients',
        'CALL sp_delete_vendor_ingredient(?);',
        [req.body.vendorIngredientID],
        'delete the vendor ingredient');
});

// RESET DB -------------------------------------------------------

// rebuilds the entire schema + sample data (sp_reset_foodmenudb in PL.SQL
// wraps sp_load_foodmenudb in DDL.sql)
app.post('/reset', (req, res) => {
    runProcedure(res, '/',
        'CALL sp_reset_foodmenudb();',
        [],
        'reset the database');
});

app.listen(PORT, () => {
    console.log(`Express started on http://localhost:${PORT}; press Ctrl-C to terminate.`);
});

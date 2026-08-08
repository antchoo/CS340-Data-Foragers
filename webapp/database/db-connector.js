/*
    The Data Foragers - Group 41 CS340 Summer 2026 OSU
    Anton Choo and Borislava Grigorova

    Creates the MySQL connection pool used by app.js. Credentials come from
    a local .env file (see .env.example) so they are never committed.
*/

require('dotenv').config();
const mysql = require('mysql2');

const pool = mysql.createPool({
    waitForConnections: true,
    connectionLimit: 10,
    host: process.env.DB_HOST || 'classmysql.engr.oregonstate.edu',
    user: process.env.DB_USER || 'cs340_onid',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_DATABASE || 'cs340_onid'
}).promise();

module.exports = pool;

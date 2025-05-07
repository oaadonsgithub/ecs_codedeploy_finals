// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0


const express = require('express');
const bodyParser = require('body-parser');
var session = require('express-session');
const MongoStore = require("connect-mongo");
const port = 5000;
const app = express();
const { db } = require('./db');
const authRouter = require('./auth');
const hospitalRouter = require('./hospital');

app.use(bodyParser.json())
app.use(bodyParser.urlencoded({
    extended: true
}))

app.use(session({
    secret: 'gfgsecret',
    resave: false,
    saveUninitialized: true,
    store: MongoStore.create({
        client: db.getClient(),
        dbName: 'testdb',
        collectionName: "sessions",
        stringify: false,
        autoRemove: "interval",
        autoRemoveInterval: 1
    })
}));

app.use('/', authRouter);
app.use('/', hospitalRouter);

app.listen(port, () => {
    console.log(`server started on ${port}`);
});

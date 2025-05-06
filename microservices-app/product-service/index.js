// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0

const express = require('express');
const app = express();
app.use(express.json());

const products = [{ id: 101, name: 'Laptop' }];

app.get('/products', (req, res) => {
  res.json(products);
});

app.listen(3002, () => {
  console.log('Product service running on port 3002');
});

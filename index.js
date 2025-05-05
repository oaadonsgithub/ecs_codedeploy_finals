// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0

const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (_req, res) => {
  res.send('Hello from my Node.js app!');
});

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});

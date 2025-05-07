// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0


const express = require('express');
const mongoose = require('mongoose');
const { Patient, Doctor } = require('./db');
require('dotenv').config();

const app = express();
app.use(express.json());

app.get('/', (req, res) => {
  res.send('Hospital Appointment API is running');
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});

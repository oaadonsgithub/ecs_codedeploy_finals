// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0


const mongoose = require('mongoose');
require('dotenv').config();

mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
});

const db = mongoose.connection;

db.on('error', (err) => {
  console.error('Connection error:', err);
});

db.once('open', () => {
  console.log("MongoDB connection successful!");
});

const PatientSchema = new mongoose.Schema({
  name: String,
  username: { type: String, unique: true },
  password: String,
  age: Number,
  email: { type: String, unique: true },
  mobile: { type: Number, unique: true },
});

const DoctorSchema = new mongoose.Schema({
  name: String,
  username: { type: String, unique: true },
  password: String,
  age: Number,
  email: { type: String, unique: true },
  mobile: { type: Number, unique: true },
  speciality: String,
});

const Patient = mongoose.model('Patient', PatientSchema, 'patient');
const Doctor = mongoose.model('Doctor', DoctorSchema, 'doctor');

module.exports = { db, Patient, Doctor };

// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0


const mongoose = require('mongoose');
require('dotenv').config();

const MONGO_URI = process.env.MONGO_URI || "mongodb+srv://oaamongose:XDX3WDTyLQdUeFCr@cluster0.spo1bms.mongodb.net/hospital?retryWrites=true&w=majority&appName=Cluster0";

mongoose.connect(MONGO_URI, {
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

const AppointmentSchema = new mongoose.Schema({
  doctorid: { type: mongoose.Schema.Types.ObjectId, ref: 'Doctor' },
  patientid: { type: mongoose.Schema.Types.ObjectId, ref: 'Patient' },
  appointmentdate: {
    type: Date,
    required: true
  },
  slotnumber: {
    type: Number,
    required: true
  }
}, { timestamps: true });

const AppointmentAvailabilitySchema = new mongoose.Schema({
  doctorid: { type: mongoose.Schema.Types.ObjectId, ref: 'Doctor' },
  appointmentdate: { type: Date },
  appointmentsavailable: Object
}, { timestamps: true });

const Patient = mongoose.model('Patient', PatientSchema, 'patient');
const Doctor = mongoose.model('Doctor', DoctorSchema, 'doctor');
const Appointment = mongoose.model('Appointment', AppointmentSchema, 'appointments');
const AppointmentAvailability = mongoose.model('AppointmentAvailability', AppointmentAvailabilitySchema, 'appointmentavailability');

module.exports = { db, Patient, Doctor, Appointment, AppointmentAvailability };

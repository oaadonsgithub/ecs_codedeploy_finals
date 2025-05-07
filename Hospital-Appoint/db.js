// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0


//db.js

const mongoose = require('mongoose');

//database connection
mongoose.connect("mongodb+srv://oaamongose:XDX3WDTyLQdUeFCr@cluster0.spo1bms.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0");

const db = mongoose.connection;

db.on('error', console.error.bind(console, 'connection error:'));


db.once('open', function () {
    console.log("Connection Successful!");
});

//model and schema creation
var PatientSchema = mongoose.Schema({
    name: String,
    username: { type: String, unique: true },
    password: String,
    age: { type: Number },
    email: { type: String, unique: true },
    mobile: { type: Number, unique: true },
});

var DoctorSchema = mongoose.Schema({
    name: String,
    username: { type: String, unique: true },
    password: String,
    age: { type: Number },
    email: { type: String, unique: true },
    mobile: { type: Number, unique: true },
    speciality: { type: String },
});

var AppointmentSchema = mongoose.Schema({
    doctorid: { type: mongoose.ObjectId, ref: 'Doctor' },
    patientid: { type: mongoose.ObjectId },
    appointmentdate: {
        type: Date,
        default: () => new Date("<YYYY-mm-dd>"),
        required: 'Must Have Appointment Date'
    },
    slotnumber: {
        type: Number,
        required: 'Must Have Slot Number'
    }
}, { timestamps: true })

var AppointmentAvailabilitySchema = mongoose.Schema({
    doctorid: { type: mongoose.ObjectId, ref: 'Doctor' },
    appointmentdate: {
        type: Date,
        ref: 'Appointment'
    },
    appointmentsavailable: {
        type: Object
    }
}, { timestamps: true })

var Patient = mongoose.model('Patient', PatientSchema, 'patient');
var Doctor = mongoose.model('Doctor', DoctorSchema, 'doctor');
var Appointment = mongoose
                      .model('Appointment', AppointmentSchema, 'appointments');
var AppointmentAvailability = mongoose
                              .model('AppointmentAvailability', 
                                        AppointmentAvailabilitySchema,
                                     'appointmentavailability');

module.exports = { db, Patient, Doctor, Appointment, AppointmentAvailability };
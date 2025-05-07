// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0




//hospital.js

const express = require('express');
var { Patient, Doctor, Appointment, AppointmentAvailability } = require('./db');
var router = express.Router();
var passport = require('passport');

const appointmentsArray = {
    "1": { slotname: "9AM TO 10AM", availability: true, appintmentid: null },
    "2": { slotname: "10AM TO 11AM", availability: true, appintmentid: null },
    "3": { slotname: "11AM TO 12PM", availability: true, appintmentid: null },
    "4": { slotname: "12PM TO 1PM", availability: true, appintmentid: null },
    "5": { slotname: "3PM TO 4PM", availability: true, appintmentid: null },
    "6": { slotname: "4PM TO 5PM", availability: true, appintmentid: null },
    "7": { slotname: "5PM TO 6PM", availability: true, appintmentid: null },
    "8": { slotname: "6PM TO 7PM", availability: true, appintmentid: null },
    "9": { slotname: "7PM TO 8PM", availability: true, appintmentid: null },
    "10": { slotname: "8PM TO 9PM", availability: true, appintmentid: null },
    "11": { slotname: "9PM TO 10PM", availability: true, appintmentid: null },
}

//home endpoint
router.get('/', (req, res) => {
    res.send("Welcome To Hospital Appointment System");
});

//route for getting all patients from database
router.get('/getpatients', async (req, res) => {
    const patients = await Patient.find({});
    res.send({ status: 200, users: patients });
})

//route for getting all doctors from database
router.get('/getdoctors', async (req, res) => {
    const doctors = await Doctor.find({});
    res.send({ status: 200, users: doctors });
})


//route for creating a new appointment
router.post('/bookappointment', async (req, res) => {
    //new appointment from request body 
    var appointmentdata = req.body;

    //authentication
    passport.authenticate('jwt', { session: false }, async (err, user) => {
        if (err || !user) {
            res.send({ status: 401, message: "Not Authorized" });
        } else {
            if (!user.isDoctor) {
                // saving appointment to db
                Doctor.findOne({ _id: appointmentdata.doctorid }).then((doctor) => {
                    if (doctor) {
                        Appointment.findOne({ doctorid: doctor["_id"], appointmentdate: new Date(appointmentdata.appointmentdate.toString()), slotnumber: appointmentdata.slotnumber }).then((appointment) => {
                            if (appointment || slotnumber > 11) {
                                res.send({ status: 200, message: "Selected Slot is not available" });
                            }
                            else {
                                var appointment = new Appointment({
                                    doctorid: appointmentdata.doctorid,
                                    patientid: user.userid,
                                    appointmentdate: new Date(appointmentdata.appointmentdate.toString()),
                                    slotnumber: appointmentdata.slotnumber
                                })

                                appointment.save().then((appointment) => {
                                    AppointmentAvailability.findOne({ doctorid: appointment.doctorid, appointmentdate: appointment.appointmentdate }).then((appointmentmap) => {
                                        if (appointmentmap) {
                                            var appointmentavailability = appointmentmap.appointmentsavailable;
                                            appointmentavailability[appointmentdata.slotnumber].availability = false;
                                            appointmentavailability[appointmentdata.slotnumber].appintmentid = appointment["_id"];
                                            AppointmentAvailability.where({ _id: appointmentmap["_id"] }).updateOne({ appointmentsavailable: appointmentavailability }).then((updateres) => {
                                                if (updateres) {
                                                    res.send({ status: 200, message: `Appointment Booked Successfully. Appointment ID is ${appointment["_id"]}` });
                                                }
                                                else {
                                                    res.send({ status: 500, message: "Internal Server Error" })
                                                }
                                            })
                                        }
                                        else {
                                            var appointmentavailability = appointmentsArray;
                                            appointmentavailability[appointmentdata.slotnumber].availability = false;
                                            appointmentavailability[appointmentdata.slotnumber].appintmentid = appointment["_id"];
                                            var appointmentavailabilityrecord = new AppointmentAvailability({
                                                doctorid: appointment.doctorid,
                                                appointmentdate: appointment.appointmentdate,
                                                appointmentsavailable: appointmentavailability
                                            })
                                            appointmentavailabilityrecord.save().then((appointmentres) => {
                                                if (appointmentres) {
                                                    res.send({ status: 200, message: `Appointment Booked Successfully. Appointment ID is ${appointment["_id"]}` })
                                                }
                                                else {
                                                    res.send({ status: 500, message: "Internal Server Error" });
                                                }
                                            })
                                        }
                                    })
                                }).catch((err) => {
                                    res.send({ status: 500, message: "Internal Server Error" });
                                })
                            }
                        }).catch((err) => {
                            console.log(err);
                        })
                    }
                    else {
                        res.send({ status: 200, message: "Selected Doctor Does Not Exist" });
                    }
                })
            }
            else {
                res.send({ status: 401, message: "This action cannot be performed by doctor" });
            }
        }
    })(req, res);
})

//route for creating a new appointment
router.delete('/cancelappointment', async (req, res) => {
    //new appointment from request body 
    var appointmentdata = req.body;

    //authentication
    passport.authenticate('jwt', { session: false }, async (err, user) => {
        if (err || !user) {
            res.send({ status: 401, message: "Not Authorized" });
        } else {
            if (!user.isDoctor) {
                // finding and deleting appointment from db
                Appointment.findOne({ _id: appointmentdata.appointmentid }).then((appointment) => {
                    if (appointment) {
                        if (user.userid === appointment.patientid.toString()) {
                            Appointment.deleteOne({ _id: appointment["_id"] }).then((deleteres) => {
                                if (deleteres) {
                                    AppointmentAvailability.findOne({ doctorid: appointment.doctorid, appointmentdate: appointment.appointmentdate }).then((appointmentmap) => {
                                        var appointmentavailability = appointmentmap.appointmentsavailable;
                                        appointmentavailability[appointment.slotnumber].availability = true;
                                        appointmentavailability[appointment.slotnumber].appintmentid = null;
                                        AppointmentAvailability.where({ _id: appointmentmap["_id"] }).updateOne({ appointmentsavailable: appointmentavailability }).then((updateres) => {
                                            if (updateres) {
                                                res.send({ status: 200, message: `Appointment with Appointment ID : ${appointment["_id"]} is canceled successfully. ` });
                                            }
                                            else {
                                                res.send({ status: 500, message: "Internal Server Error" })
                                            }
                                        })
                                    })
                                }
                                else {
                                    res.send({ status: 500, message: "Internal Server Error" });
                                }
                            })
                        }
                        else {
                            res.send({ status: 200, message: "Invalid Appointment Number" });
                        }
                    }
                    else {
                        res.send({ status: 200, message: "Appointment Does Not Exist" });
                    }
                }).catch((err) => {
                    console.log(err);
                })
            }
            else {
                res.send({ status: 401, message: "This action cannot be performed by doctor" });
            }
        }
    })(req, res);
})

router.get("/getappointments", (req, res) => {
    //authentication
    passport.authenticate('jwt', { session: false }, async (err, user) => {
        if (err || !user) {
            res.send({ status: 401, message: "Not Authorized" });
        } else {
            if (!user.isDoctor) {
                // fetching appointments from db for patient
                Appointment.find({ patientid: user.userid }).then((appointments) => {
                    if (appointments) {
                        res.send({ status: 200, appointments: appointments });
                    }
                    else {
                        res.send({ status: 500, message: "Internal Server Error" });
                    }
                }).catch((err) => {
                    console.log(err);
                })
            }
            else {
                // fetching appointments from db for doctor
                Appointment.find({ doctorid: user.userid }).then((appointments) => {
                    if (appointments) {
                        res.send({ status: 200, appointments: appointments });
                    }
                    else {
                        res.send({ status: 500, message: "Internal Server Error" });
                    }
                }).catch((err) => {
                    console.log(err);
                })
            }
        }
    })(req, res);
})

module.exports = router;
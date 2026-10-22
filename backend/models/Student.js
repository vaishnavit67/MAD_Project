const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Please enter full name'],
      trim: true,
      minlength: [2, 'Full name must be at least 2 characters'],
    },
    email: {
      type: String,
      required: [true, 'Please enter email address'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [
        /^[a-zA-Z0-9._%+-]+@(cb\.students\.amrita\.edu|students\.amrita\.edu|([a-zA-Z0-9.-]+\.students\.amrita\.edu))$/,
        'Students must use an Amrita student email (@cb.students.amrita.edu)',
      ],
    },
    phone: {
      type: String,
      required: [true, 'Please enter phone number'],
      unique: true,
      trim: true,
      match: [/^[6-9]\d{9}$/, 'Phone number must be a valid 10-digit mobile number'],
    },
    rollNumber: {
      type: String,
      required: [true, 'Please enter Roll Number / Campus ID'],
      trim: true,
      minlength: [3, 'Roll number must be at least 3 characters'],
    },
    password: {
      type: String,
      default: '',
    },
    passwordHash: {
      type: String,
      default: '',
    },
    role: {
      type: String,
      default: 'Student',
    },
    category: {
      type: String,
      default: 'students',
    },
  },
  {
    timestamps: true,
    strict: false,
    collection: 'students', // MongoDB collection name
  }
);

studentSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.password;
  return obj;
};

module.exports = mongoose.model('Student', studentSchema, 'students');

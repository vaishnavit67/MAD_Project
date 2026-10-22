const mongoose = require('mongoose');

const facultySchema = new mongoose.Schema(
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
        /^[a-zA-Z0-9._%+-]+@(cb\.amrita\.edu|amrita\.edu|([a-zA-Z0-9.-]+\.amrita\.edu))$/,
        'Faculty must use an Amrita faculty email (@cb.amrita.edu)',
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
      required: [true, 'Please enter Campus / Employee ID'],
      trim: true,
      minlength: [3, 'Campus ID must be at least 3 characters'],
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
      default: 'Faculty',
    },
    category: {
      type: String,
      default: 'faculty',
    },
  },
  {
    timestamps: true,
    strict: false,
    collection: 'faculty', // MongoDB collection name
  }
);

// Do not return password by default when converting to JSON
facultySchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.password;
  return obj;
};

module.exports = mongoose.model('Faculty', facultySchema, 'faculty');

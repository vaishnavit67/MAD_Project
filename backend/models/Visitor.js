const mongoose = require('mongoose');

const visitorSchema = new mongoose.Schema(
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
        /^[a-zA-Z0-9._%+-]+@gmail\.com$/,
        'Visitors must use a Gmail address (@gmail.com)',
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
      required: [true, 'Please enter Visitor ID / Pass Number'],
      trim: true,
      minlength: [3, 'Visitor ID must be at least 3 characters'],
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
      default: 'Visitor',
    },
    category: {
      type: String,
      default: 'visitors',
    },
  },
  {
    timestamps: true,
    strict: false,
    collection: 'visitors', // MongoDB collection name
  }
);

visitorSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.password;
  return obj;
};

module.exports = mongoose.model('Visitor', visitorSchema, 'visitors');

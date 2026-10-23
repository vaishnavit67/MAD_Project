const mongoose = require('mongoose');

const clubSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Club name is required'],
      trim: true,
      maxlength: [100, 'Club name cannot exceed 100 characters'],
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      enum: {
        values: ['Technical', 'Creative', 'Cultural', 'Sports', 'Academic', 'Other'],
        message: 'Invalid category. Must be Technical, Creative, Cultural, Sports, Academic, or Other',
      },
      default: 'Technical',
      index: true,
    },
    description: {
      type: String,
      required: [true, 'Description is required'],
      trim: true,
      maxlength: [1000, 'Description cannot exceed 1000 characters'],
    },
    imageUrl: {
      type: String,
      default: null,
      trim: true,
    },
    membersCount: {
      type: Number,
      default: 1,
      min: 0,
    },
    members: {
      type: [String],
      default: [],
    },
    createdBy: {
      type: String,
      required: [true, 'Faculty creator identifier is required'],
      index: true,
    },
    createdByName: {
      type: String,
      default: 'Faculty Member',
      trim: true,
    },
    leadEmail: {
      type: String,
      trim: true,
      default: '',
    },
    joinRequests: [
      {
        userId: { type: String, required: true },
        userName: { type: String, default: '' },
        userEmail: { type: String, default: '' },
        userPhone: { type: String, default: '' },
        userRollNumber: { type: String, default: '' },
        status: {
          type: String,
          enum: ['pending', 'approved', 'rejected'],
          default: 'pending',
        },
        requestedAt: { type: Date, default: Date.now },
        reviewedAt: { type: Date, default: null },
      },
    ],
  },
  {
    timestamps: true,
    collection: 'clubs',
  }
);

clubSchema.methods.toJSON = function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  return obj;
};

module.exports = mongoose.model('Club', clubSchema, 'clubs');

const mongoose = require('mongoose');

const lostFoundSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Please provide an item title'],
      trim: true,
      minlength: [2, 'Title must be at least 2 characters'],
    },
    description: {
      type: String,
      required: [true, 'Please provide an item description'],
      trim: true,
    },
    category: {
      type: String,
      required: [true, 'Please provide a category (e.g. Electronics, ID Cards, Books)'],
      trim: true,
    },
    type: {
      type: String,
      required: [true, 'Please specify type as lost or found'],
      enum: {
        values: ['lost', 'found'],
        message: 'Type must be either "lost" or "found"',
      },
      lowercase: true,
      trim: true,
    },
    location: {
      type: String,
      required: [true, 'Please specify the campus location where the item was lost or found'],
      trim: true,
    },
    date: {
      type: Date,
      required: [true, 'Please provide the date when the item was lost or found'],
      default: Date.now,
    },
    imageUrl: {
      type: String,
      default: null,
      trim: true,
    },
    ownerId: {
      type: String,
      required: [true, 'Owner ID (Firebase UID) is required'],
      trim: true,
      index: true,
    },
    ownerName: {
      type: String,
      required: [true, 'Owner name is required'],
      trim: true,
    },
    status: {
      type: String,
      enum: {
        values: ['active', 'claimed', 'resolved'],
        message: 'Status must be active, claimed, or resolved',
      },
      default: 'active',
      index: true,
    },
  },
  {
    timestamps: true,
    collection: 'lost_found', // Mapped to 'lost_found' collection
  }
);

lostFoundSchema.methods.toJSON = function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  return obj;
};

module.exports = mongoose.model('LostFound', lostFoundSchema, 'lost_found');

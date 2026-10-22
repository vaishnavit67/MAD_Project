const mongoose = require('mongoose');

const checkpointSchema = new mongoose.Schema(
  {
    label: { type: String, default: '' },
    title: { type: String, default: '' },
    instruction: { type: String, default: '' },
    dx: { type: Number, default: 0.0 },
    dy: { type: Number, default: 0.0 },
    isStop: { type: Boolean, default: false },
    latitude: { type: Number, default: null },
    longitude: { type: Number, default: null },
  },
  { _id: false }
);

const campusLocationSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Location name is required'],
      unique: true,
      trim: true,
    },
    category: {
      type: String,
      required: [true, 'Location category is required'],
      trim: true,
    },
    description: {
      type: String,
      default: '',
      trim: true,
    },
    distance: {
      type: String,
      default: '850 m',
    },
    walkingTime: {
      type: String,
      default: '~10 min',
    },
    buildingCode: {
      type: String,
      default: '',
      trim: true,
    },
    floorCount: {
      type: Number,
      default: 1,
    },
    isFavorite: {
      type: Boolean,
      default: false,
    },
    keywords: {
      type: [String],
      default: [],
    },
    checkpoints: {
      type: [checkpointSchema],
      default: [],
    },
    latitude: {
      type: Number,
      default: null,
    },
    longitude: {
      type: Number,
      default: null,
    },
  },
  {
    timestamps: true,
    collection: 'locations', // Stored in 'locations' collection in MongoDB
  }
);

// Map _id to id when converted to JSON
campusLocationSchema.methods.toJSON = function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  return obj;
};

module.exports = mongoose.model('CampusLocation', campusLocationSchema, 'locations');

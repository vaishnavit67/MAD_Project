const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Event title is required'],
      trim: true,
      maxlength: [150, 'Title cannot exceed 150 characters'],
    },
    date: {
      type: Date,
      required: [true, 'Event date is required'],
      index: true,
    },
    timeString: {
      type: String,
      required: [true, 'Start time is required (e.g. 10:00 AM)'],
      trim: true,
    },
    endTimeString: {
      type: String,
      default: null,
      trim: true,
    },
    location: {
      type: String,
      required: [true, 'Event location/venue is required'],
      trim: true,
    },
    description: {
      type: String,
      required: [true, 'Event description is required'],
      trim: true,
      maxlength: [2000, 'Description cannot exceed 2000 characters'],
    },
    organizer: {
      type: String,
      required: [true, 'Organizer is required'],
      trim: true,
    },
    availableSeats: {
      type: Number,
      default: 100,
      min: 0,
    },
    capacity: {
      type: Number,
      default: 100,
      min: 1,
    },
    participantCount: {
      type: Number,
      default: 0,
      min: 0,
    },
    status: {
      type: String,
      enum: ['upcoming', 'ongoing', 'past', 'cancelled'],
      default: 'upcoming',
      index: true,
    },
    category: {
      type: String,
      enum: ['Hackathon', 'Technology', 'Workshop', 'Cultural', 'Sports', 'Club', 'Career', 'Academic', 'Other'],
      default: 'Other',
      index: true,
    },
    imageUrl: {
      type: String,
      default: null,
      trim: true,
    },
    featured: {
      type: Boolean,
      default: false,
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
    participants: {
      type: [String],
      default: [],
    },
  },
  {
    timestamps: true,
    collection: 'events',
  }
);

eventSchema.methods.toJSON = function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  return obj;
};

module.exports = mongoose.model('Event', eventSchema, 'events');

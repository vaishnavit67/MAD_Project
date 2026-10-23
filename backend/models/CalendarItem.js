const mongoose = require('mongoose');

const calendarItemSchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      required: true,
      index: true,
    },
    userRole: {
      type: String,
      enum: ['Student', 'Faculty', 'Visitor'],
      default: 'Student',
      index: true,
    },
    itemType: {
      type: String,
      enum: ['class', 'task', 'event'],
      required: true,
      index: true,
    },
    title: {
      type: String,
      required: [true, 'Title is required'],
      trim: true,
    },
    description: {
      type: String,
      default: '',
      trim: true,
    },
    subject: {
      type: String,
      default: '',
      trim: true,
    },
    location: {
      type: String,
      default: '',
      trim: true,
    },
    instructor: {
      type: String,
      default: '',
      trim: true,
    },
    date: {
      type: Date,
      default: null,
      index: true,
    },
    startTime: {
      type: String,
      default: '09:00 AM',
      trim: true,
    },
    endTime: {
      type: String,
      default: '10:00 AM',
      trim: true,
    },
    daysOfWeek: {
      type: [Number],
      default: [], // 1 = Monday, 7 = Sunday
    },
    completed: {
      type: Boolean,
      default: false,
    },
    priority: {
      type: String,
      enum: ['low', 'medium', 'high'],
      default: 'medium',
    },
    colorHex: {
      type: String,
      default: '#2196F3',
    },
    reminderMinutes: {
      type: Number,
      default: 15,
    },
  },
  {
    timestamps: true,
    collection: 'calendar_items',
  }
);

calendarItemSchema.methods.toJSON = function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  return obj;
};

module.exports = mongoose.model('CalendarItem', calendarItemSchema, 'calendar_items');

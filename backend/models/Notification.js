const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    recipientId: {
      type: String,
      default: 'all', // 'all', specific user ID, or 'role:Student'
      index: true,
    },
    recipientRole: {
      type: String,
      enum: ['Student', 'Faculty', 'Visitor', 'All'],
      default: 'All',
      index: true,
    },
    title: {
      type: String,
      required: [true, 'Notification title is required'],
      trim: true,
    },
    message: {
      type: String,
      required: [true, 'Notification message is required'],
      trim: true,
    },
    type: {
      type: String,
      enum: ['task', 'event', 'club', 'club_accepted', 'lost_found', 'reminder', 'system', 'class'],
      default: 'system',
      index: true,
    },
    isRead: {
      type: Boolean,
      default: false,
    },
    readBy: {
      type: [String],
      default: [],
    },
    relatedId: {
      type: String,
      default: null,
    },
    relatedEventId: {
      type: String,
      default: null,
    },
    relatedTaskId: {
      type: String,
      default: null,
    },
    relatedClubId: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
    collection: 'notifications',
  }
);

notificationSchema.methods.toJSON = function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  return obj;
};

module.exports = mongoose.model('Notification', notificationSchema, 'notifications');

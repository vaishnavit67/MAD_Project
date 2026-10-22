const mongoose = require('mongoose');

const lostFoundClaimSchema = new mongoose.Schema(
  {
    itemId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'LostFound',
      required: [true, 'Item ID is required'],
      index: true,
    },
    claimantId: {
      type: String,
      required: [true, 'Claimant ID (Firebase UID) is required'],
      trim: true,
      index: true,
    },
    claimantName: {
      type: String,
      default: 'Anonymous Claimant',
      trim: true,
    },
    message: {
      type: String,
      required: [true, 'Please provide a message explaining your claim or proof of ownership'],
      trim: true,
      minlength: [3, 'Claim message must be at least 3 characters'],
    },
    proofImageUrl: {
      type: String,
      default: null,
      trim: true,
    },
    status: {
      type: String,
      enum: {
        values: ['pending', 'approved', 'rejected'],
        message: 'Status must be pending, approved, or rejected',
      },
      default: 'pending',
      index: true,
    },
  },
  {
    timestamps: true,
    collection: 'lost_found_claims', // Mapped to 'lost_found_claims' collection
  }
);

lostFoundClaimSchema.methods.toJSON = function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  return obj;
};

module.exports = mongoose.model('LostFoundClaim', lostFoundClaimSchema, 'lost_found_claims');

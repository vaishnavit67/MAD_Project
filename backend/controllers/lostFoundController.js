const mongoose = require('mongoose');
const LostFound = require('../models/LostFound');
const LostFoundClaim = require('../models/LostFoundClaim');
const {
  sendLostItemReportConfirmation,
  sendLostItemClaimNotification,
  sendClaimStatusNotification,
} = require('../services/emailService');

/**
 * Validates MongoDB ObjectId
 */
function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(id) && String(new mongoose.Types.ObjectId(id)) === id;
}

/**
 * Validates URL format for images (supports http, https, blob, data URIs)
 */
function isValidUrl(string) {
  if (!string || !string.trim()) return true; // Optional
  const trimmed = string.trim();
  if (
    trimmed.startsWith('http://') ||
    trimmed.startsWith('https://') ||
    trimmed.startsWith('data:image/') ||
    trimmed.startsWith('blob:') ||
    trimmed.startsWith('/') ||
    trimmed.startsWith('file:')
  ) {
    return true;
  }
  try {
    new URL(trimmed);
    return true;
  } catch (_) {
    return false;
  }
}

/**
 * @desc    Get all Lost & Found items (sorted newest first, with search & filters)
 * @route   GET /api/lost-found
 * @access  Public
 */
exports.getItems = async (req, res) => {
  try {
    const { type, category, status, search } = req.query;
    const filter = {};

    // 1. Filter by status: Default to 'active' unless explicitly requested
    if (status && status !== 'all') {
      filter.status = status.toLowerCase();
    } else if (!status) {
      filter.status = 'active';
    }

    // 2. Filter by type: 'lost' or 'found'
    if (type && ['lost', 'found'].includes(type.trim().toLowerCase())) {
      filter.type = type.trim().toLowerCase();
    }

    // 3. Filter by category
    if (category && category !== 'All') {
      filter.category = new RegExp(`^${category.trim()}$`, 'i');
    }

    // 4. Keyword search across title, description, location, and category
    if (search && search.trim()) {
      const searchRegex = new RegExp(search.trim(), 'i');
      filter.$or = [
        { title: searchRegex },
        { description: searchRegex },
        { location: searchRegex },
        { category: searchRegex },
      ];
    }

    // Fetch items sorted by newest first (createdAt: -1)
    // Note: Do not expose private claim details in the public item feed
    const items = await LostFound.find(filter).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: items.length,
      items: items.map((i) => i.toJSON()),
    });
  } catch (error) {
    console.error('[Get Lost & Found Items Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Server error while retrieving items',
    });
  }
};

/**
 * @desc    Get single item by ID
 * @route   GET /api/lost-found/:id
 * @access  Public
 */
exports.getItemById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!isValidObjectId(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid item ID format',
      });
    }

    const item = await LostFound.findById(id);

    if (!item) {
      return res.status(404).json({
        success: false,
        message: `Lost/Found item with ID '${id}' not found`,
      });
    }

    return res.status(200).json({
      success: true,
      item: item.toJSON(),
    });
  } catch (error) {
    console.error('[Get Item By ID Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Server error while retrieving item',
    });
  }
};

/**
 * @desc    Create a new lost or found listing
 * @route   POST /api/lost-found
 * @access  Protected (Requires Firebase / Auth token)
 */
exports.createItem = async (req, res) => {
  try {
    const { title, description, category, type, location, date, imageUrl, ownerName } = req.body;

    // 1. Validate required fields
    if (!title || !title.trim()) {
      return res.status(400).json({ success: false, message: 'Item title is required' });
    }
    if (!description || !description.trim()) {
      return res.status(400).json({ success: false, message: 'Item description is required' });
    }
    if (!category || !category.trim()) {
      return res.status(400).json({ success: false, message: 'Item category is required' });
    }
    if (!type || !['lost', 'found'].includes(type.trim().toLowerCase())) {
      return res.status(400).json({ success: false, message: 'Type must be specified as either "lost" or "found"' });
    }
    if (!location || !location.trim()) {
      return res.status(400).json({ success: false, message: 'Campus location is required' });
    }

    // 2. Validate Image URL if provided
    if (imageUrl && !isValidUrl(imageUrl)) {
      return res.status(400).json({ success: false, message: 'Invalid imageUrl format' });
    }

    // 3. Security: Derive ownerId strictly from verified token, or fallback to body/demo
    const ownerId = (req.user && (req.user.uid || req.user.id)) || req.body.ownerId || 'seed-student-001';
    const finalOwnerName = (ownerName && ownerName.trim()) || (req.user && req.user.name) || 'Campus Member';

    // Parse date
    let itemDate = new Date();
    if (date) {
      const parsed = new Date(date);
      if (!isNaN(parsed.getTime())) {
        itemDate = parsed;
      }
    }

    const newItem = await LostFound.create({
      title: title.trim(),
      description: description.trim(),
      category: category.trim(),
      type: type.trim().toLowerCase(),
      location: location.trim(),
      date: itemDate,
      imageUrl: imageUrl ? imageUrl.trim() : null,
      ownerId,
      ownerName: finalOwnerName,
      status: 'active',
    });

    // Send confirmation email asynchronously
    sendLostItemReportConfirmation({
      userEmail: (req.user && req.user.email) || req.body.ownerEmail,
      userName: finalOwnerName,
      itemTitle: newItem.title,
      itemType: newItem.type,
      location: newItem.location,
    }).catch((e) => console.error('[Email Notice]:', e.message));

    return res.status(201).json({
      success: true,
      message: 'Item listing created successfully',
      item: newItem.toJSON(),
    });
  } catch (error) {
    console.error('[Create Item Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Server error while creating item',
    });
  }
};

/**
 * @desc    Update a lost or found listing (owner or admin only)
 * @route   PUT /api/lost-found/:id
 * @access  Protected (Owner or Admin)
 */
exports.updateItem = async (req, res) => {
  try {
    const { id } = req.params;

    if (!isValidObjectId(id)) {
      return res.status(400).json({ success: false, message: 'Invalid item ID format' });
    }

    const item = await LostFound.findById(id);

    if (!item) {
      return res.status(404).json({ success: false, message: 'Lost/Found item not found' });
    }

    // Security: Only owner or admin can update listing
    const isOwner = item.ownerId === req.user.uid;
    const isAdmin = req.user.role === 'admin';
    if (!isOwner && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden. You do not have permission to modify this listing.',
      });
    }

    const { title, description, category, type, location, date, imageUrl, status } = req.body;

    if (title) item.title = title.trim();
    if (description) item.description = description.trim();
    if (category) item.category = category.trim();
    if (type && ['lost', 'found'].includes(type.trim().toLowerCase())) {
      item.type = type.trim().toLowerCase();
    }
    if (location) item.location = location.trim();
    if (date) {
      const parsed = new Date(date);
      if (!isNaN(parsed.getTime())) item.date = parsed;
    }
    if (imageUrl !== undefined) {
      if (imageUrl && !isValidUrl(imageUrl)) {
        return res.status(400).json({ success: false, message: 'Invalid imageUrl format' });
      }
      item.imageUrl = imageUrl ? imageUrl.trim() : null;
    }
    if (status && ['active', 'claimed', 'resolved'].includes(status.trim().toLowerCase())) {
      item.status = status.trim().toLowerCase();
    }

    await item.save();

    return res.status(200).json({
      success: true,
      message: 'Item listing updated successfully',
      item: item.toJSON(),
    });
  } catch (error) {
    console.error('[Update Item Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Server error while updating item',
    });
  }
};

/**
 * @desc    Delete a lost or found listing (owner or admin only)
 * @route   DELETE /api/lost-found/:id
 * @access  Protected (Owner or Admin)
 */
exports.deleteItem = async (req, res) => {
  try {
    const { id } = req.params;

    if (!isValidObjectId(id)) {
      return res.status(400).json({ success: false, message: 'Invalid item ID format' });
    }

    const item = await LostFound.findById(id);

    if (!item) {
      return res.status(404).json({ success: false, message: 'Lost/Found item not found' });
    }

    // Security: Only owner or admin can delete
    const isOwner = item.ownerId === req.user.uid;
    const isAdmin = req.user.role === 'admin';
    if (!isOwner && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden. You do not have permission to delete this listing.',
      });
    }

    // Delete item
    await LostFound.findByIdAndDelete(id);

    // Clean up all associated claims
    await LostFoundClaim.deleteMany({ itemId: id });

    return res.status(200).json({
      success: true,
      message: 'Item listing and associated claims deleted successfully',
    });
  } catch (error) {
    console.error('[Delete Item Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Server error while deleting item',
    });
  }
};

/**
 * @desc    Submit a claim request for an item
 * @route   POST /api/lost-found/:id/claims
 * @access  Protected (Any authenticated user except the owner)
 */
exports.createClaim = async (req, res) => {
  try {
    const { id } = req.params;
    const { message, proofImageUrl, claimantName } = req.body;

    if (!isValidObjectId(id)) {
      return res.status(400).json({ success: false, message: 'Invalid item ID format' });
    }

    const item = await LostFound.findById(id);

    if (!item) {
      return res.status(404).json({ success: false, message: 'Lost/Found item not found' });
    }

    // 1. Prevent owner from claiming their own item
    if (item.ownerId === req.user.uid) {
      return res.status(400).json({
        success: false,
        message: 'You cannot submit a claim for an item you posted.',
      });
    }

    // 2. Prevent claiming inactive or resolved items
    if (item.status !== 'active') {
      return res.status(400).json({
        success: false,
        message: `Cannot submit claim. Item is currently marked as ${item.status}.`,
      });
    }

    // 3. Validate message
    if (!message || !message.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a message explaining your claim or proof of ownership',
      });
    }

    // 4. Validate proof image URL if supplied
    if (proofImageUrl && !isValidUrl(proofImageUrl)) {
      return res.status(400).json({ success: false, message: 'Invalid proofImageUrl format' });
    }

    // 5. Prevent duplicate active claims (pending or approved) from the same user
    const existingActiveClaim = await LostFoundClaim.findOne({
      itemId: item._id,
      claimantId: req.user.uid,
      status: { $in: ['pending', 'approved'] },
    });

    if (existingActiveClaim) {
      return res.status(409).json({
        success: false,
        message: 'You have already submitted an active claim for this item. Please wait for the owner to review it.',
      });
    }

    const newClaim = await LostFoundClaim.create({
      itemId: item._id,
      claimantId: req.user.uid,
      claimantName: (claimantName && claimantName.trim()) || req.user.name || 'Anonymous Claimant',
      message: message.trim(),
      proofImageUrl: proofImageUrl ? proofImageUrl.trim() : null,
      status: 'pending',
    });

    // Send claim notification email to item owner asynchronously
    sendLostItemClaimNotification({
      ownerEmail: item.ownerEmail || (item.ownerId && item.ownerId.includes('@') ? item.ownerId : null),
      ownerName: item.ownerName,
      claimantName: newClaim.claimantName,
      itemTitle: item.title,
      claimMessage: newClaim.message,
    }).catch((e) => console.error('[Email Notice]:', e.message));

    return res.status(201).json({
      success: true,
      message: 'Claim request submitted successfully',
      claim: newClaim.toJSON(),
    });
  } catch (error) {
    console.error('[Create Claim Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Server error while submitting claim',
    });
  }
};

/**
 * @desc    Retrieve all claim requests for an item (owner or admin only)
 * @route   GET /api/lost-found/:id/claims
 * @access  Protected (Owner or Admin only)
 */
exports.getItemClaims = async (req, res) => {
  try {
    const { id } = req.params;

    if (!isValidObjectId(id)) {
      return res.status(400).json({ success: false, message: 'Invalid item ID format' });
    }

    const item = await LostFound.findById(id);

    if (!item) {
      return res.status(404).json({ success: false, message: 'Lost/Found item not found' });
    }

    // Security: Only the item owner or an administrator can view claims
    const isOwner = item.ownerId === req.user.uid;
    const isAdmin = req.user.role === 'admin';
    if (!isOwner && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Only the owner of this listing can view claim requests.',
      });
    }

    const claims = await LostFoundClaim.find({ itemId: item._id }).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: claims.length,
      itemTitle: item.title,
      claims: claims.map((c) => c.toJSON()),
    });
  } catch (error) {
    console.error('[Get Claims Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Server error while retrieving claims',
    });
  }
};

/**
 * @desc    Approve or reject a claim (owner or admin only)
 * @route   PATCH /api/lost-found/:id/claims/:claimId
 * @access  Protected (Owner or Admin only)
 */
exports.updateClaimStatus = async (req, res) => {
  try {
    const { id, claimId } = req.params;
    const { status } = req.body;

    if (!isValidObjectId(id) || !isValidObjectId(claimId)) {
      return res.status(400).json({ success: false, message: 'Invalid item ID or claim ID format' });
    }

    const item = await LostFound.findById(id);
    if (!item) {
      return res.status(404).json({ success: false, message: 'Lost/Found item not found' });
    }

    // Security: Only the item owner or admin can review claims
    const isOwner = item.ownerId === req.user.uid;
    const isAdmin = req.user.role === 'admin';
    if (!isOwner && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Only the owner of this listing can approve or reject claims.',
      });
    }

    const claim = await LostFoundClaim.findOne({ _id: claimId, itemId: item._id });
    if (!claim) {
      return res.status(404).json({
        success: false,
        message: `Claim request '${claimId}' not found for this item`,
      });
    }

    // Validate status
    if (!status || !['approved', 'rejected'].includes(status.trim().toLowerCase())) {
      return res.status(400).json({
        success: false,
        message: 'Claim status must be specified as "approved" or "rejected"',
      });
    }

    const newStatus = status.trim().toLowerCase();
    claim.status = newStatus;
    await claim.save();

    // If claim is approved, mark the item as 'claimed'
    if (newStatus === 'approved') {
      item.status = 'claimed';
      await item.save();

      // Automatically reject other pending claims for this item
      await LostFoundClaim.updateMany(
        { itemId: item._id, _id: { $ne: claim._id }, status: 'pending' },
        { status: 'rejected' }
      );
    }

    // Send email to claimant asynchronously
    sendClaimStatusNotification({
      claimantEmail: claim.claimantEmail || (claim.claimantId && claim.claimantId.includes('@') ? claim.claimantId : null),
      claimantName: claim.claimantName,
      itemTitle: item.title,
      status: newStatus,
      ownerName: item.ownerName,
    }).catch((e) => console.error('[Email Notice]:', e.message));

    return res.status(200).json({
      success: true,
      message: `Claim request has been ${newStatus} successfully.`,
      claim: claim.toJSON(),
      item: item.toJSON(),
    });
  } catch (error) {
    console.error('[Update Claim Status Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Server error while updating claim status',
    });
  }
};

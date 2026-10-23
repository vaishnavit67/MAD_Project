const express = require('express');
const { requireAuth, optionalAuth } = require('../middleware/firebaseAuth');
const lostFoundController = require('../controllers/lostFoundController');

const router = express.Router();

/**
 * @route   GET /api/lost-found
 * @desc    Retrieve active items sorted newest first with filters (type, category, search)
 * @access  Public
 */
router.get('/', optionalAuth, lostFoundController.getItems);

/**
 * @route   GET /api/lost-found/:id
 * @desc    Retrieve single item by ID
 * @access  Public
 */
router.get('/:id', optionalAuth, lostFoundController.getItemById);

/**
 * @route   POST /api/lost-found
 * @desc    Create a lost or found listing (sets ownerId from verified token)
 * @access  Protected
 */
router.post('/', requireAuth, lostFoundController.createItem);

/**
 * @route   PUT /api/lost-found/:id
 * @desc    Update an item (owner or admin only)
 * @access  Protected
 */
router.put('/:id', requireAuth, lostFoundController.updateItem);

/**
 * @route   DELETE /api/lost-found/:id
 * @desc    Delete an item and its claims (owner or admin only)
 * @access  Protected
 */
router.delete('/:id', requireAuth, lostFoundController.deleteItem);

/**
 * @route   POST /api/lost-found/:id/claims
 * @desc    Submit a claim request for an item (prevent duplicates and self-claim)
 * @access  Protected
 */
router.post('/:id/claims', requireAuth, lostFoundController.createClaim);

/**
 * @route   GET /api/lost-found/:id/claims
 * @desc    Retrieve claim requests for the item (owner or admin only)
 * @access  Protected
 */
router.get('/:id/claims', requireAuth, lostFoundController.getItemClaims);

/**
 * @route   PATCH /api/lost-found/:id/claims/:claimId
 * @desc    Approve or reject a claim (owner or admin only)
 * @access  Protected
 */
router.patch('/:id/claims/:claimId', requireAuth, lostFoundController.updateClaimStatus);

/**
 * @route   POST /api/lost-found/:id/found-notice
 * @desc    Notify the owner of a lost item that someone found it
 * @access  Optional Auth / Public
 */
router.post('/:id/found-notice', optionalAuth, lostFoundController.notifyItemFound);

module.exports = router;


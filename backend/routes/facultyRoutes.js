const express = require('express');
const router = express.Router();
const LostFoundClaim = require('../models/LostFoundClaim');
const LostFound = require('../models/LostFound');
const Club = require('../models/Club');
const Event = require('../models/Event');
const { requireAuth, requireFaculty } = require('../middleware/firebaseAuth');

/**
 * @route   GET /api/faculty/dashboard-stats
 * @desc    Get real counts for the faculty dashboard (pending claims, clubs, events, unresolved items)
 * @access  Protected (Faculty)
 */
router.get('/dashboard-stats', requireAuth, requireFaculty, async (req, res) => {
  try {
    const [pendingClaimsCount, activeClubsCount, upcomingEventsCount, unresolvedItemsCount] = await Promise.all([
      LostFoundClaim.countDocuments({ status: 'pending' }),
      Club.countDocuments(),
      Event.countDocuments({ date: { $gte: new Date() } }),
      LostFound.countDocuments({ status: { $nin: ['claimed', 'resolved'] } }),
    ]);

    return res.status(200).json({
      success: true,
      stats: {
        pendingClaimsCount,
        activeClubsCount,
        upcomingEventsCount,
        unresolvedItemsCount,
      },
    });
  } catch (error) {
    console.error('[Faculty Stats Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Error fetching faculty dashboard stats.',
    });
  }
});

/**
 * @route   GET /api/faculty/pending-requests
 * @desc    Get all pending verification requests / claims requiring faculty approval
 * @access  Protected (Faculty)
 */
router.get('/pending-requests', requireAuth, requireFaculty, async (req, res) => {
  try {
    const claims = await LostFoundClaim.find({ status: 'pending' })
      .populate('itemId', 'name title category location imageUrl status type')
      .sort({ createdAt: -1 });

    const formattedRequests = claims.map((claim) => {
      const item = claim.itemId;
      return {
        id: claim._id.toString(),
        itemId: item ? item._id.toString() : null,
        itemTitle: item ? (item.title || item.name) : 'Unknown Item',
        itemCategory: item ? item.category : 'General',
        itemLocation: item ? item.location : 'Campus',
        itemImageUrl: item ? item.imageUrl : null,
        claimantName: claim.claimantName || 'Anonymous Student',
        claimantId: claim.claimantId,
        message: claim.message,
        proofImageUrl: claim.proofImageUrl,
        submittedAt: claim.createdAt,
        status: claim.status,
      };
    });

    return res.status(200).json({
      success: true,
      count: formattedRequests.length,
      requests: formattedRequests,
    });
  } catch (error) {
    console.error('[Get Pending Requests Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Error fetching pending requests.',
    });
  }
});

/**
 * @route   PATCH /api/faculty/claims/:id
 * @desc    Approve or reject a claim (Faculty moderation)
 * @access  Protected (Faculty)
 */
router.patch('/claims/:id', requireAuth, requireFaculty, async (req, res) => {
  try {
    const { status } = req.body;
    if (!status || !['approved', 'rejected'].includes(status.toLowerCase())) {
      return res.status(400).json({
        success: false,
        message: 'Status must be either "approved" or "rejected".',
      });
    }

    const cleanStatus = status.toLowerCase();
    const claim = await LostFoundClaim.findById(req.params.id);

    if (!claim) {
      return res.status(404).json({
        success: false,
        message: 'Claim not found.',
      });
    }

    claim.status = cleanStatus;
    await claim.save();

    // If claim is approved, mark the lost & found item as claimed/resolved
    if (cleanStatus === 'approved') {
      await LostFound.findByIdAndUpdate(claim.itemId, {
        status: 'claimed',
      });
    }

    return res.status(200).json({
      success: true,
      message: `Claim request has been marked as ${cleanStatus}.`,
      claim,
    });
  } catch (error) {
    console.error('[Update Claim Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to update claim status.',
    });
  }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const Club = require('../models/Club');
const { requireAuth, optionalAuth, requireFaculty } = require('../middleware/firebaseAuth');
const {
  sendClubJoinRequestToTeacher,
  sendClubJoinRequestConfirmationToStudent,
  sendClubJoinApprovalToStudent,
} = require('../services/emailService');

/**
 * @route   GET /api/clubs
 * @desc    Get all clubs with optional category & search filter
 * @access  Public
 */
router.get('/', optionalAuth, async (req, res) => {
  try {
    const { category, search } = req.query;
    const filter = {};

    if (category && category !== 'All') {
      filter.category = category;
    }

    if (search && search.trim().length > 0) {
      const q = search.trim();
      filter.$or = [
        { name: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } },
      ];
    }

    const clubs = await Club.find(filter).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: clubs.length,
      clubs,
    });
  } catch (error) {
    console.error('[Get Clubs Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch clubs from database.',
    });
  }
});

/**
 * @route   GET /api/clubs/:id
 * @desc    Get a single club by ID
 * @access  Public
 */
router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const club = await Club.findById(req.params.id);
    if (!club) {
      return res.status(404).json({
        success: false,
        message: 'Club not found.',
      });
    }

    return res.status(200).json({
      success: true,
      club,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Error fetching club.',
    });
  }
});

/**
 * @route   POST /api/clubs
 * @desc    Create a new club (Faculty only)
 * @access  Protected (Faculty)
 */
router.post('/', requireAuth, requireFaculty, async (req, res) => {
  try {
    const { name, category, description, imageUrl, initialMembersCount } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Club name is required.',
      });
    }

    if (!description || !description.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Club description is required.',
      });
    }

    const validCategories = ['Technical', 'Creative', 'Cultural', 'Sports', 'Academic', 'Other'];
    const assignedCategory = validCategories.includes(category) ? category : 'Technical';

    const newClub = await Club.create({
      name: name.trim(),
      category: assignedCategory,
      description: description.trim(),
      imageUrl: imageUrl && imageUrl.trim().length > 0 ? imageUrl.trim() : null,
      membersCount: initialMembersCount && !isNaN(initialMembersCount) ? parseInt(initialMembersCount, 10) : 1,
      members: [req.user.name || 'Faculty Member', req.user.uid, req.user.email].filter(Boolean),
      createdBy: req.user.uid,
      createdByName: req.user.name || 'Faculty Member',
      leadEmail: req.user.email || '',
      joinRequests: [],
    });

    return res.status(201).json({
      success: true,
      message: 'Club created successfully!',
      club: newClub,
    });
  } catch (error) {
    console.error('[Create Club Error]:', error);
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to create club.',
    });
  }
});

/**
 * @route   PUT /api/clubs/:id
 * @desc    Update a club (Faculty only)
 * @access  Protected (Faculty)
 */
router.put('/:id', requireAuth, requireFaculty, async (req, res) => {
  try {
    const { name, category, description, imageUrl } = req.body;
    const club = await Club.findById(req.params.id);

    if (!club) {
      return res.status(404).json({
        success: false,
        message: 'Club not found.',
      });
    }

    if (name) club.name = name.trim();
    if (category) club.category = category;
    if (description) club.description = description.trim();
    if (imageUrl !== undefined) club.imageUrl = imageUrl ? imageUrl.trim() : null;

    await club.save();

    return res.status(200).json({
      success: true,
      message: 'Club updated successfully!',
      club,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to update club.',
    });
  }
});

/**
 * @route   DELETE /api/clubs/:id
 * @desc    Delete a club (Faculty only)
 * @access  Protected (Faculty)
 */
router.delete('/:id', requireAuth, requireFaculty, async (req, res) => {
  try {
    const club = await Club.findByIdAndDelete(req.params.id);
    if (!club) {
      return res.status(404).json({
        success: false,
        message: 'Club not found.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Club removed successfully.',
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to delete club.',
    });
  }
});

/**
 * @route   POST /api/clubs/:id/join
 * @desc    Request to join a club (Faculty joins directly or leads; Students create pending request for teacher approval)
 * @access  Protected (Student/Faculty)
 */
router.post('/:id/join', requireAuth, async (req, res) => {
  try {
    const role = (req.user.role || '').toLowerCase();
    if (role === 'visitor') {
      return res.status(403).json({
        success: false,
        message: 'Visitors cannot join campus clubs. Club membership is reserved for students and faculty.',
      });
    }

    const club = await Club.findById(req.params.id);
    if (!club) {
      return res.status(404).json({
        success: false,
        message: 'Club not found.',
      });
    }

    // 1. If user is the Faculty creator / lead
    const isLead =
      club.createdBy === req.user.uid ||
      (club.leadEmail && club.leadEmail.toLowerCase() === (req.user.email || '').toLowerCase()) ||
      (role === 'faculty' && club.createdByName === req.user.name);

    if (isLead) {
      return res.status(200).json({
        success: true,
        message: `You are the Faculty Lead of ${club.name}.`,
        club,
        isLead: true,
        isJoined: true,
      });
    }

    // 2. If user is already an approved member
    const userIdentifiers = [req.user.uid, req.user.name, req.user.email].filter(Boolean);
    const isAlreadyMember = club.members.some((m) => userIdentifiers.includes(m));

    if (isAlreadyMember) {
      return res.status(200).json({
        success: true,
        message: `You are already a member of ${club.name}!`,
        club,
        isJoined: true,
      });
    }

    // 3. If user is another Faculty member, allow direct joining
    if (role === 'faculty') {
      club.members.push(req.user.name || req.user.uid);
      club.membersCount += 1;
      await club.save();
      return res.status(200).json({
        success: true,
        message: `Successfully joined ${club.name}!`,
        club,
        isJoined: true,
      });
    }

    // 4. Student join flow: Requires Teacher Approval
    // Check if there is already a pending request
    const existingPending = (club.joinRequests || []).find(
      (r) => (r.userId === req.user.uid || (r.userEmail && r.userEmail === req.user.email)) && r.status === 'pending'
    );

    if (existingPending) {
      return res.status(200).json({
        success: true,
        message: `Your request to join ${club.name} is already submitted and awaiting faculty approval.`,
        club,
        isPending: true,
      });
    }

    // Create new join request
    const joinReq = {
      userId: req.user.uid,
      userName: req.user.name || 'Campus Student',
      userEmail: req.user.email || '',
      userPhone: req.user.phone || '',
      userRollNumber: req.user.rollNumber || '',
      status: 'pending',
      requestedAt: new Date(),
    };

    club.joinRequests.push(joinReq);
    await club.save();

    // Trigger emails asynchronously
    sendClubJoinRequestToTeacher({
      teacherEmail: club.leadEmail || 'faculty@amrita.edu',
      teacherName: club.createdByName || 'Faculty Lead',
      studentName: req.user.name || 'Student',
      studentEmail: req.user.email || '',
      studentRoll: req.user.rollNumber || '',
      clubName: club.name,
    }).catch((e) => console.error('[Email Notice]:', e.message));

    sendClubJoinRequestConfirmationToStudent({
      studentEmail: req.user.email || '',
      studentName: req.user.name || 'Student',
      clubName: club.name,
      teacherName: club.createdByName || 'Faculty Lead',
    }).catch((e) => console.error('[Email Notice]:', e.message));

    return res.status(200).json({
      success: true,
      message: `Join request submitted! You will become a member once approved by ${club.createdByName || 'the Faculty Lead'}.`,
      club,
      isPending: true,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to submit join request.',
    });
  }
});

/**
 * @route   GET /api/clubs/:id/requests
 * @desc    Get all pending and past join requests for this club (Faculty lead only)
 * @access  Protected (Faculty)
 */
router.get('/:id/requests', requireAuth, async (req, res) => {
  try {
    const club = await Club.findById(req.params.id);
    if (!club) {
      return res.status(404).json({ success: false, message: 'Club not found.' });
    }

    // Faculty check
    const isLead =
      club.createdBy === req.user.uid ||
      (club.leadEmail && club.leadEmail.toLowerCase() === (req.user.email || '').toLowerCase()) ||
      (req.user.role || '').toLowerCase() === 'faculty' ||
      req.user.role === 'admin';

    if (!isLead) {
      return res.status(403).json({
        success: false,
        message: 'Only the club faculty lead can view membership requests.',
      });
    }

    return res.status(200).json({
      success: true,
      count: (club.joinRequests || []).length,
      requests: club.joinRequests || [],
      clubName: club.name,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch join requests.',
    });
  }
});

/**
 * @route   PATCH /api/clubs/:id/requests/:requestId
 * @desc    Approve or reject a student join request (Faculty lead only)
 * @access  Protected (Faculty)
 */
router.patch('/:id/requests/:requestId', requireAuth, async (req, res) => {
  try {
    const { status } = req.body;
    if (!status || !['approved', 'rejected'].includes(status.toLowerCase())) {
      return res.status(400).json({
        success: false,
        message: 'Status must be "approved" or "rejected".',
      });
    }

    const club = await Club.findById(req.params.id);
    if (!club) {
      return res.status(404).json({ success: false, message: 'Club not found.' });
    }

    const isLead =
      club.createdBy === req.user.uid ||
      (club.leadEmail && club.leadEmail.toLowerCase() === (req.user.email || '').toLowerCase()) ||
      (req.user.role || '').toLowerCase() === 'faculty' ||
      req.user.role === 'admin';

    if (!isLead) {
      return res.status(403).json({
        success: false,
        message: 'Only the club faculty lead can review membership requests.',
      });
    }

    const request = club.joinRequests.id(req.params.requestId) ||
      club.joinRequests.find((r) => r._id.toString() === req.params.requestId);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Join request not found.',
      });
    }

    const newStatus = status.toLowerCase();
    request.status = newStatus;
    request.reviewedAt = new Date();

    if (newStatus === 'approved') {
      const studentIdentifier = request.userName || request.userId;
      if (!club.members.includes(studentIdentifier)) {
        club.members.push(studentIdentifier);
        if (request.userId && !club.members.includes(request.userId)) {
          club.members.push(request.userId);
        }
        club.membersCount += 1;
      }

      // Send approval email to student
      sendClubJoinApprovalToStudent({
        studentEmail: request.userEmail,
        studentName: request.userName || 'Student',
        clubName: club.name,
        teacherName: club.createdByName || 'Faculty Lead',
      }).catch((e) => console.error('[Email Notice]:', e.message));
    }

    await club.save();

    return res.status(200).json({
      success: true,
      message: `Join request has been ${newStatus}.`,
      request,
      club,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to update join request.',
    });
  }
});

module.exports = router;

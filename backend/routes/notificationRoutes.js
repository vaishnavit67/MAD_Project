const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification');
const { requireAuth, optionalAuth } = require('../middleware/firebaseAuth');

// Default role-specific seed notifications
function getDefaultSeedsForRole(role) {
  const cleanRole = (role || 'Student').trim().toLowerCase();
  const now = new Date();

  if (cleanRole === 'faculty') {
    return [
      {
        recipientRole: 'Faculty',
        title: 'Club Join Request 👥',
        message: 'A student requested to join your club. Review and approve in Clubs tab.',
        type: 'club',
        createdAt: new Date(now.getTime() - 25 * 60 * 1000),
      },
      {
        recipientRole: 'Faculty',
        title: 'Teaching Lecture Reminder 📚',
        message: 'CS301 Advanced Operating Systems starts at 10:00 AM at Hall 102.',
        type: 'class',
        createdAt: new Date(now.getTime() - 75 * 60 * 1000),
      },
      {
        recipientRole: 'Faculty',
        title: 'Faculty Council Notice 🏛️',
        message: 'Department Academic Council Meeting on Friday at 3:00 PM in Conference Room.',
        type: 'system',
        createdAt: new Date(now.getTime() - 4 * 3600 * 1000),
      },
      {
        recipientRole: 'Faculty',
        title: 'Event Organizer Update 🚀',
        message: 'Your hosted workshop "AI and ML Workshop" has 45 registered students.',
        type: 'event',
        createdAt: new Date(now.getTime() - 24 * 3600 * 1000),
      },
    ];
  }

  if (cleanRole === 'visitor') {
    return [
      {
        recipientRole: 'Visitor',
        title: 'Welcome to Amrita Campus 👋',
        message: 'Explore campus landmarks, open auditoriums, and visitor navigation from the Map screen.',
        type: 'system',
        createdAt: new Date(now.getTime() - 30 * 60 * 1000),
      },
      {
        recipientRole: 'Visitor',
        title: 'Visitor Parking Available 🅿️',
        message: 'Designated guest parking spaces are located adjacent to the Main Entrance gate.',
        type: 'reminder',
        createdAt: new Date(now.getTime() - 2 * 3600 * 1000),
      },
      {
        recipientRole: 'Visitor',
        title: 'Public Campus Event 🎪',
        message: 'Cultural Fest - Utsav 2026 welcomes outside visitors this weekend at the Main Auditorium.',
        type: 'event',
        createdAt: new Date(now.getTime() - 24 * 3600 * 1000),
      },
      {
        recipientRole: 'Visitor',
        title: 'Campus Help Desk ℹ️',
        message: 'Security and Information Desk is open 24/7 at Administrative Block reception.',
        type: 'system',
        createdAt: new Date(now.getTime() - 48 * 3600 * 1000),
      },
    ];
  }

  // Default: Student
  return [
    {
      recipientRole: 'Student',
      title: 'Class Reminder 🔔',
      message: 'Operating Systems lecture starting at 9:00 AM at Academic Block 2, Room 204.',
      type: 'class',
      createdAt: new Date(now.getTime() - 20 * 60 * 1000),
    },
    {
      recipientRole: 'Student',
      title: 'Assignment Due ⏰',
      message: 'DBMS Laboratory Report is due today by 5:00 PM on Campus Portal.',
      type: 'task',
      createdAt: new Date(now.getTime() - 90 * 60 * 1000),
    },
    {
      recipientRole: 'Student',
      title: 'Event Reminder 🚀',
      message: 'Hackathon 3.0 starts tomorrow at 9:00 AM at Innovation Lab.',
      type: 'event',
      createdAt: new Date(now.getTime() - 3 * 3600 * 1000),
    },
    {
      recipientRole: 'Student',
      title: 'Club Notice 💡',
      message: 'Coding Club weekly peer programming session this Wednesday at 4:30 PM.',
      type: 'club',
      createdAt: new Date(now.getTime() - 24 * 3600 * 1000),
    },
    {
      recipientRole: 'Student',
      title: 'Welcome to Campus Connect 👋',
      message: 'Track your personal classes, task deadlines, and club registrations in one place.',
      type: 'system',
      createdAt: new Date(now.getTime() - 48 * 3600 * 1000),
    },
  ];
}

/**
 * @route   GET /api/notifications
 * @desc    Get user-specific and role-tailored notifications
 * @access  Optional Auth / Public with role query
 */
router.get('/', optionalAuth, async (req, res) => {
  try {
    const roleParam = req.query.role || (req.user ? req.user.role : 'Student');
    const role = (roleParam.charAt(0).toUpperCase() + roleParam.slice(1).toLowerCase()).trim();
    const userId = req.user ? (req.user.uid || req.user.id || req.user.email) : (req.query.userId || null);
    const userEmail = req.user ? req.user.email : (req.query.email || req.query.userEmail || null);
    const userName = req.user ? req.user.name : (req.query.name || req.query.userName || null);
    const sanitizedName = userName ? `student_${userName.replace(/\W/g, '_')}` : null;

    // Build filter: MUST match recipientRole (or 'All') AND recipientId (or 'all')
    const filter = {
      $and: [
        {
          $or: [
            { recipientRole: role },
            { recipientRole: 'All' },
          ],
        },
        {
          $or: [
            { recipientId: 'all' },
            ...(userId ? [{ recipientId: userId }] : []),
            ...(userEmail ? [{ recipientId: userEmail }] : []),
            ...(sanitizedName ? [{ recipientId: sanitizedName }] : []),
          ],
        },
      ],
    };

    let notifications = await Notification.find(filter).sort({ createdAt: -1 }).limit(50);

    // If no notifications exist yet for this role, auto-seed defaults into MongoDB
    if (notifications.length === 0) {
      const defaultSeeds = getDefaultSeedsForRole(role);
      await Notification.insertMany(defaultSeeds);
      notifications = await Notification.find(filter).sort({ createdAt: -1 }).limit(50);
    }

    const unreadCount = notifications.filter((n) => {
      if (userId && n.readBy && n.readBy.includes(userId)) return false;
      return !n.isRead;
    }).length;

    return res.status(200).json({
      success: true,
      role,
      count: notifications.length,
      unreadCount,
      notifications,
    });
  } catch (error) {
    console.error('[Get Notifications Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Error retrieving notifications.',
    });
  }
});

/**
 * @route   POST /api/notifications
 * @desc    Create a new notification (used for club approvals, event signups, claim updates)
 * @access  Protected
 */
router.post('/', optionalAuth, async (req, res) => {
  try {
    const { recipientId, recipientRole, title, message, type, relatedEventId, relatedTaskId, relatedClubId } = req.body;

    if (!title || !message) {
      return res.status(400).json({
        success: false,
        message: 'Title and message are required.',
      });
    }

    const notification = await Notification.create({
      recipientId: recipientId || 'all',
      recipientRole: recipientRole || 'All',
      title: title.trim(),
      message: message.trim(),
      type: type || 'system',
      relatedEventId,
      relatedTaskId,
      relatedClubId,
    });

    return res.status(201).json({
      success: true,
      notification,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Error creating notification.',
    });
  }
});

/**
 * @route   PATCH /api/notifications/:id/read
 * @desc    Mark a notification as read
 * @access  Protected
 */
router.patch('/:id/read', requireAuth, async (req, res) => {
  try {
    const userId = req.user.uid || req.user.id || req.user.email;
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    notification.isRead = true;
    if (userId && !notification.readBy.includes(userId)) {
      notification.readBy.push(userId);
    }
    await notification.save();

    return res.status(200).json({
      success: true,
      notification,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

/**
 * @route   PATCH /api/notifications/read-all
 * @desc    Mark all notifications as read for current user
 * @access  Protected
 */
router.patch('/read-all', requireAuth, async (req, res) => {
  try {
    const userId = req.user.uid || req.user.id || req.user.email;
    const roleParam = req.user.role || 'Student';
    const role = (roleParam.charAt(0).toUpperCase() + roleParam.slice(1).toLowerCase()).trim();

    await Notification.updateMany(
      {
        $or: [
          { recipientRole: role },
          { recipientRole: 'All' },
          { recipientId: userId },
        ],
      },
      {
        $set: { isRead: true },
        $addToSet: { readBy: userId },
      }
    );

    return res.status(200).json({
      success: true,
      message: 'All notifications marked as read.',
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

/**
 * @route   DELETE /api/notifications/:id
 * @desc    Delete a notification
 * @access  Protected
 */
router.delete('/:id', requireAuth, async (req, res) => {
  try {
    await Notification.findByIdAndDelete(req.params.id);
    return res.status(200).json({
      success: true,
      message: 'Notification deleted.',
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;

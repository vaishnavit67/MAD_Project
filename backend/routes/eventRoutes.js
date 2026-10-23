const express = require('express');
const router = express.Router();
const Event = require('../models/Event');
const Notification = require('../models/Notification');
const { requireAuth, optionalAuth, requireFaculty } = require('../middleware/firebaseAuth');

/**
 * @route   GET /api/events
 * @desc    Get all events with optional filters (category, time, search, role)
 * @access  Public / Optional Auth
 */
router.get('/', optionalAuth, async (req, res) => {
  try {
    const { category, time, search, role } = req.query;
    const userRole = (role || (req.user ? req.user.role : '')).toLowerCase();
    const filter = {};

    if (category && category !== 'All') {
      filter.category = category;
    } else if (userRole === 'visitor') {
      // Visitors browse open public/cultural/tech events only
      filter.category = { $in: ['Cultural', 'Sports', 'Technology', 'Hackathon', 'Other'] };
    }

    const now = new Date();
    if (time === 'Today') {
      const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
      filter.date = { $gte: startOfDay, $lte: endOfDay };
    } else if (time === 'This Week') {
      const startOfWeek = new Date(now);
      startOfWeek.setDate(now.getDate() - now.getDay());
      const endOfWeek = new Date(startOfWeek);
      endOfWeek.setDate(startOfWeek.getDate() + 7);
      filter.date = { $gte: startOfWeek, $lte: endOfWeek };
    } else if (time === 'Upcoming') {
      filter.date = { $gte: now };
    } else if (time === 'Past') {
      filter.date = { $lt: now };
    }

    if (search && search.trim().length > 0) {
      const q = search.trim();
      filter.$or = [
        { title: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } },
        { location: { $regex: q, $options: 'i' } },
        { organizer: { $regex: q, $options: 'i' } },
      ];
    }

    const events = await Event.find(filter).sort({ date: 1 });

    return res.status(200).json({
      success: true,
      count: events.length,
      events,
    });
  } catch (error) {
    console.error('[Get Events Error]:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch events from database.',
    });
  }
});

/**
 * @route   GET /api/events/my-registrations
 * @desc    Get all events registered by the authenticated user
 * @access  Protected
 */
router.get('/my-registrations', requireAuth, async (req, res) => {
  try {
    const userId = req.user.uid || req.user.id;
    const userEmail = req.user.email;
    const userName = req.user.name;

    const identifiers = [userId, userEmail, userName].filter(Boolean);

    const registeredEvents = await Event.find({
      participants: { $in: identifiers },
    }).sort({ date: 1 });

    return res.status(200).json({
      success: true,
      count: registeredEvents.length,
      registeredIds: registeredEvents.map((e) => e._id.toString()),
      events: registeredEvents,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch user registrations.',
    });
  }
});

/**
 * @route   GET /api/events/:id
 * @desc    Get a single event by ID
 * @access  Public
 */
router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found.',
      });
    }

    return res.status(200).json({
      success: true,
      event,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Error retrieving event.',
    });
  }
});

/**
 * @route   POST /api/events
 * @desc    Create a new campus event (Faculty only)
 * @access  Protected (Faculty)
 */
router.post('/', requireAuth, requireFaculty, async (req, res) => {
  try {
    const {
      title,
      description,
      date,
      timeString,
      endTimeString,
      location,
      organizer,
      category,
      capacity,
      availableSeats,
      imageUrl,
      featured,
    } = req.body;

    if (!title || !description || !date || !timeString || !location) {
      return res.status(400).json({
        success: false,
        message: 'Missing required event fields (title, description, date, timeString, location).',
      });
    }

    const eventDate = new Date(date);
    const parsedCapacity = Number(capacity) || 100;
    const parsedAvailable = availableSeats !== undefined ? Number(availableSeats) : parsedCapacity;

    const newEvent = await Event.create({
      title: title.trim(),
      description: description.trim(),
      date: eventDate,
      timeString: timeString.trim(),
      endTimeString: endTimeString ? endTimeString.trim() : null,
      location: location.trim(),
      organizer: organizer ? organizer.trim() : (req.user.name || 'Faculty Member'),
      category: category || 'Other',
      capacity: parsedCapacity,
      availableSeats: parsedAvailable,
      imageUrl: imageUrl ? imageUrl.trim() : null,
      featured: Boolean(featured),
      createdBy: req.user.uid || req.user.id || 'faculty_user',
      createdByName: req.user.name || 'Faculty Member',
      participants: [req.user.uid || req.user.id], // Faculty host is automatically enrolled
    });

    // Notify campus members about the new event
    await Notification.create({
      recipientRole: 'All',
      title: 'New Campus Event 📢',
      message: `"${newEvent.title}" has been announced by ${newEvent.organizer}. Happening at ${newEvent.location}.`,
      type: 'event',
      relatedEventId: newEvent._id.toString(),
    });

    return res.status(201).json({
      success: true,
      message: 'Event created and published to campus successfully!',
      event: newEvent,
    });
  } catch (error) {
    console.error('[Create Event Error]:', error);
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to create event.',
    });
  }
});

/**
 * @route   PUT /api/events/:id
 * @desc    Update an event (Faculty only)
 * @access  Protected (Faculty)
 */
router.put('/:id', requireAuth, requireFaculty, async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) {
      return res.status(404).json({ success: false, message: 'Event not found.' });
    }

    const updates = req.body;
    if (updates.title) event.title = updates.title.trim();
    if (updates.description) event.description = updates.description.trim();
    if (updates.date) event.date = new Date(updates.date);
    if (updates.timeString) event.timeString = updates.timeString.trim();
    if (updates.location) event.location = updates.location.trim();
    if (updates.organizer) event.organizer = updates.organizer.trim();
    if (updates.category) event.category = updates.category;
    if (updates.imageUrl !== undefined) event.imageUrl = updates.imageUrl ? updates.imageUrl.trim() : null;
    if (updates.capacity !== undefined) event.capacity = updates.capacity;
    if (updates.availableSeats !== undefined) event.availableSeats = updates.availableSeats;
    if (updates.featured !== undefined) event.featured = Boolean(updates.featured);

    await event.save();

    return res.status(200).json({
      success: true,
      message: 'Event updated successfully!',
      event,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to update event.',
    });
  }
});

/**
 * @route   DELETE /api/events/:id
 * @desc    Delete an event (Faculty only)
 * @access  Protected (Faculty)
 */
router.delete('/:id', requireAuth, requireFaculty, async (req, res) => {
  try {
    const event = await Event.findByIdAndDelete(req.params.id);
    if (!event) {
      return res.status(404).json({ success: false, message: 'Event not found.' });
    }

    return res.status(200).json({
      success: true,
      message: 'Event deleted successfully.',
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to delete event.',
    });
  }
});

/**
 * @route   POST /api/events/:id/register
 * @desc    Register for an event
 * @access  Protected
 */
router.post('/:id/register', requireAuth, async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) {
      return res.status(404).json({ success: false, message: 'Event not found.' });
    }

    const memberId = req.user.uid || req.user.id || req.user.email;
    const memberName = req.user.name || memberId;

    const isOrganizer =
      event.createdBy === memberId ||
      event.organizer === memberName ||
      ((req.user.role || '').toLowerCase() === 'faculty' && event.createdByName === memberName);

    if (isOrganizer) {
      return res.status(200).json({
        success: true,
        message: `You are the faculty organizer of ${event.title}!`,
        event,
        isOrganizer: true,
        isRegistered: true,
      });
    }

    if (event.participants && (event.participants.includes(memberId) || event.participants.includes(memberName))) {
      return res.status(200).json({
        success: true,
        message: `You are already registered for ${event.title}!`,
        event,
        isRegistered: true,
      });
    }

    if (event.availableSeats > 0) {
      event.availableSeats -= 1;
    }
    event.participantCount += 1;
    if (!event.participants) event.participants = [];
    event.participants.push(memberId);
    await event.save();

    // Create confirmation in-app notification in MongoDB for the member
    try {
      await Notification.create({
        recipientId: memberId,
        recipientRole: req.user.role || 'Student',
        title: 'Event Registered 🎉',
        message: `You are confirmed for "${event.title}" on ${new Date(event.date).toLocaleDateString()} at ${event.timeString}. 📍 ${event.location}`,
        type: 'event',
        relatedEventId: event._id.toString(),
      });
    } catch (_) {}

    return res.status(200).json({
      success: true,
      message: `Registration confirmed for ${event.title}!`,
      event,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Registration failed.',
    });
  }
});

/**
 * @route   POST /api/events/:id/unregister
 * @desc    Unregister from an event
 * @access  Protected
 */
router.post('/:id/unregister', requireAuth, async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) {
      return res.status(404).json({ success: false, message: 'Event not found.' });
    }

    const memberId = req.user.uid || req.user.id || req.user.email;
    const memberName = req.user.name || memberId;

    event.participants = (event.participants || []).filter(
      (p) => p !== memberId && p !== memberName
    );
    if (event.participantCount > 0) event.participantCount -= 1;
    event.availableSeats += 1;
    await event.save();

    return res.status(200).json({
      success: true,
      message: `Unregistered from ${event.title}.`,
      event,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Unregister failed.',
    });
  }
});

module.exports = router;

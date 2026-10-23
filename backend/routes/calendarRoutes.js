const express = require('express');
const router = express.Router();
const CalendarItem = require('../models/CalendarItem');
const { requireAuth, optionalAuth } = require('../middleware/firebaseAuth');

// Default classes seed per role
function getDefaultClassesForRole(userId, role) {
  const cleanRole = (role || 'Student').trim().toLowerCase();

  if (cleanRole === 'faculty') {
    return [
      {
        userId,
        userRole: 'Faculty',
        itemType: 'class',
        title: 'CS301 - Operating Systems (Lecture)',
        subject: 'Operating Systems',
        location: 'Lecture Hall 102, Academic Block 1',
        instructor: 'Self (Faculty)',
        startTime: '09:00 AM',
        endTime: '10:30 AM',
        daysOfWeek: [1, 3, 5], // Mon, Wed, Fri
        colorHex: '#7C3AED',
      },
      {
        userId,
        userRole: 'Faculty',
        itemType: 'class',
        title: 'CS405 - Machine Learning Lab',
        subject: 'Machine Learning',
        location: 'Computing Lab 3, Innovation Wing',
        instructor: 'Self (Faculty)',
        startTime: '02:00 PM',
        endTime: '04:30 PM',
        daysOfWeek: [2, 4], // Tue, Thu
        colorHex: '#2563EB',
      },
      {
        userId,
        userRole: 'Faculty',
        itemType: 'class',
        title: 'Department Faculty Office Hours',
        subject: 'Student Mentoring & Consultation',
        location: 'Faculty Cabin B-204',
        instructor: 'Self (Faculty)',
        startTime: '11:00 AM',
        endTime: '12:30 PM',
        daysOfWeek: [1, 2, 4], // Mon, Tue, Thu
        colorHex: '#059669',
      },
    ];
  }

  if (cleanRole === 'visitor') {
    // Visitors do not take academic classes
    return [];
  }

  // Default: Student classes
  return [
    {
      userId,
      userRole: 'Student',
      itemType: 'class',
      title: 'Operating Systems',
      subject: 'Computer Science',
      location: 'Room 204, Academic Block 2',
      instructor: 'Dr. Roopa (Faculty)',
      startTime: '09:00 AM',
      endTime: '10:00 AM',
      daysOfWeek: [1, 3, 5], // Mon, Wed, Fri
      colorHex: '#2563EB',
    },
    {
      userId,
      userRole: 'Student',
      itemType: 'class',
      title: 'Database Management Systems',
      subject: 'Computer Science',
      location: 'Hall 105, Main Block',
      instructor: 'Dr. Rajesh (Faculty)',
      startTime: '10:15 AM',
      endTime: '11:15 AM',
      daysOfWeek: [2, 4], // Tue, Thu
      colorHex: '#7C3AED',
    },
    {
      userId,
      userRole: 'Student',
      itemType: 'class',
      title: 'Machine Learning & AI',
      subject: 'Data Science',
      location: 'Lab 4, Innovation Wing',
      instructor: 'Prof. Amrita Faculty',
      startTime: '02:00 PM',
      endTime: '03:30 PM',
      daysOfWeek: [1, 2, 4], // Mon, Tue, Thu
      colorHex: '#059669',
    },
    {
      userId,
      userRole: 'Student',
      itemType: 'class',
      title: 'Design and Analysis of Algorithms',
      subject: 'Algorithms',
      location: 'Seminar Hall 3',
      instructor: 'Dr. Roopa (Faculty)',
      startTime: '11:30 AM',
      endTime: '12:30 PM',
      daysOfWeek: [3, 5], // Wed, Fri
      colorHex: '#EA580C',
    },
  ];
}

// Default tasks seed per role
function getDefaultTasksForRole(userId, role) {
  const cleanRole = (role || 'Student').trim().toLowerCase();
  const now = new Date();

  if (cleanRole === 'faculty') {
    return [
      {
        userId,
        userRole: 'Faculty',
        itemType: 'task',
        title: 'Review Midterm Question Papers',
        description: 'Verify rubric and submit to examination office.',
        date: new Date(now.getFullYear(), now.getMonth(), now.getDate(), 17, 0),
        startTime: '05:00 PM',
        completed: false,
        priority: 'high',
        colorHex: '#DC2626',
      },
      {
        userId,
        userRole: 'Faculty',
        itemType: 'task',
        title: 'Approve Student Club Memberships',
        description: 'Review pending student join requests in Coding Club.',
        date: new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 14, 0),
        startTime: '02:00 PM',
        completed: false,
        priority: 'medium',
        colorHex: '#7C3AED',
      },
      {
        userId,
        userRole: 'Faculty',
        itemType: 'task',
        title: 'Submit Lab Evaluation Grades',
        description: 'Finalize marks for Machine Learning Lab batch 1.',
        date: new Date(now.getFullYear(), now.getMonth(), now.getDate() + 3, 16, 0),
        startTime: '04:00 PM',
        completed: true,
        priority: 'medium',
        colorHex: '#059669',
      },
    ];
  }

  if (cleanRole === 'visitor') {
    return [
      {
        userId,
        userRole: 'Visitor',
        itemType: 'task',
        title: 'Guided Campus Tour',
        description: 'Meet student ambassador at Reception for campus orientation.',
        date: new Date(now.getFullYear(), now.getMonth(), now.getDate(), 11, 0),
        startTime: '11:00 AM',
        completed: false,
        priority: 'high',
        colorHex: '#2563EB',
      },
      {
        userId,
        userRole: 'Visitor',
        itemType: 'task',
        title: 'Visit Central Library & Heritage Center',
        description: 'Explore university archive and digital learning pavilion.',
        date: new Date(now.getFullYear(), now.getMonth(), now.getDate(), 15, 0),
        startTime: '03:00 PM',
        completed: false,
        priority: 'medium',
        colorHex: '#059669',
      },
    ];
  }

  // Default: Student tasks
  return [
    {
      userId,
      userRole: 'Student',
      itemType: 'task',
      title: 'DBMS Laboratory Assignment 4',
      description: 'Implement B-Tree indexing and query optimization on Atlas.',
      date: new Date(now.getFullYear(), now.getMonth(), now.getDate(), 18, 0),
      startTime: '06:00 PM',
      completed: false,
      priority: 'high',
      colorHex: '#DC2626',
    },
    {
      userId,
      userRole: 'Student',
      itemType: 'task',
      title: 'Probability & Statistics Problem Set',
      description: 'Solve questions 1 through 15 on Gaussian distributions.',
      date: new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 20, 0),
      startTime: '08:00 PM',
      completed: false,
      priority: 'medium',
      colorHex: '#2563EB',
    },
    {
      userId,
      userRole: 'Student',
      itemType: 'task',
      title: 'ML Project Presentation Slides',
      description: 'Prepare 8 slides on convolutional neural networks.',
      date: new Date(now.getFullYear(), now.getMonth(), now.getDate() + 3, 17, 0),
      startTime: '05:00 PM',
      completed: true,
      priority: 'medium',
      colorHex: '#059669',
    },
  ];
}

// ══════════════════════════════════════════════
// CLASSES ENDPOINTS
// ══════════════════════════════════════════════

/**
 * @route   GET /api/calendar/classes
 * @desc    Get user-specific timetable classes
 * @access  Optional Auth / Protected
 */
router.get('/classes', optionalAuth, async (req, res) => {
  try {
    const roleParam = req.query.role || (req.user ? req.user.role : 'Student');
    const role = (roleParam.charAt(0).toUpperCase() + roleParam.slice(1).toLowerCase()).trim();
    const userId = req.user ? (req.user.uid || req.user.id || req.user.email) : `guest_${role.toLowerCase()}`;

    let classes = await CalendarItem.find({
      userId,
      itemType: 'class',
    }).sort({ startTime: 1 });

    // Seed default role-specific classes if none exist for this user yet
    if (classes.length === 0 && role.toLowerCase() !== 'visitor') {
      const defaultClasses = getDefaultClassesForRole(userId, role);
      if (defaultClasses.length > 0) {
        await CalendarItem.insertMany(defaultClasses);
        classes = await CalendarItem.find({ userId, itemType: 'class' }).sort({ startTime: 1 });
      }
    }

    return res.status(200).json({
      success: true,
      role,
      count: classes.length,
      classes,
    });
  } catch (error) {
    console.error('[Get Classes Error]:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
});

/**
 * @route   POST /api/calendar/classes
 * @desc    Add a class for the current user
 * @access  Protected
 */
router.post('/classes', requireAuth, async (req, res) => {
  try {
    const userId = req.user.uid || req.user.id || req.user.email;
    const roleParam = req.user.role || 'Student';
    const role = (roleParam.charAt(0).toUpperCase() + roleParam.slice(1).toLowerCase()).trim();

    const { title, subject, location, instructor, startTime, endTime, daysOfWeek, colorHex } = req.body;

    if (!title) {
      return res.status(400).json({ success: false, message: 'Class title is required' });
    }

    const newClass = await CalendarItem.create({
      userId,
      userRole: role,
      itemType: 'class',
      title: title.trim(),
      subject: (subject || '').trim(),
      location: (location || '').trim(),
      instructor: (instructor || '').trim(),
      startTime: startTime || '09:00 AM',
      endTime: endTime || '10:00 AM',
      daysOfWeek: Array.isArray(daysOfWeek) ? daysOfWeek : [1, 3, 5],
      colorHex: colorHex || '#2196F3',
    });

    return res.status(201).json({
      success: true,
      classItem: newClass,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

/**
 * @route   DELETE /api/calendar/classes/:id
 * @desc    Delete a class
 * @access  Protected
 */
router.delete('/classes/:id', requireAuth, async (req, res) => {
  try {
    await CalendarItem.findByIdAndDelete(req.params.id);
    return res.status(200).json({ success: true, message: 'Class deleted successfully' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// ══════════════════════════════════════════════
// TASKS ENDPOINTS
// ══════════════════════════════════════════════

/**
 * @route   GET /api/calendar/tasks
 * @desc    Get user-specific tasks
 * @access  Optional Auth / Protected
 */
router.get('/tasks', optionalAuth, async (req, res) => {
  try {
    const roleParam = req.query.role || (req.user ? req.user.role : 'Student');
    const role = (roleParam.charAt(0).toUpperCase() + roleParam.slice(1).toLowerCase()).trim();
    const userId = req.user ? (req.user.uid || req.user.id || req.user.email) : `guest_${role.toLowerCase()}`;

    let tasks = await CalendarItem.find({
      userId,
      itemType: 'task',
    }).sort({ date: 1, createdAt: -1 });

    // Seed default role-specific tasks if none exist for this user yet
    if (tasks.length === 0) {
      const defaultTasks = getDefaultTasksForRole(userId, role);
      if (defaultTasks.length > 0) {
        await CalendarItem.insertMany(defaultTasks);
        tasks = await CalendarItem.find({ userId, itemType: 'task' }).sort({ date: 1, createdAt: -1 });
      }
    }

    return res.status(200).json({
      success: true,
      role,
      count: tasks.length,
      tasks,
    });
  } catch (error) {
    console.error('[Get Tasks Error]:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
});

/**
 * @route   POST /api/calendar/tasks
 * @desc    Create a task for the current user
 * @access  Protected
 */
router.post('/tasks', requireAuth, async (req, res) => {
  try {
    const userId = req.user.uid || req.user.id || req.user.email;
    const roleParam = req.user.role || 'Student';
    const role = (roleParam.charAt(0).toUpperCase() + roleParam.slice(1).toLowerCase()).trim();

    const { title, description, date, startTime, priority, reminderMinutes, colorHex } = req.body;

    if (!title) {
      return res.status(400).json({ success: false, message: 'Task title is required' });
    }

    const newTask = await CalendarItem.create({
      userId,
      userRole: role,
      itemType: 'task',
      title: title.trim(),
      description: (description || '').trim(),
      date: date ? new Date(date) : new Date(),
      startTime: startTime || '05:00 PM',
      priority: priority || 'medium',
      reminderMinutes: reminderMinutes || 15,
      colorHex: colorHex || '#2196F3',
      completed: false,
    });

    return res.status(201).json({
      success: true,
      task: newTask,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

/**
 * @route   PUT /api/calendar/tasks/:id
 * @desc    Update task status or details
 * @access  Protected
 */
router.put('/tasks/:id', requireAuth, async (req, res) => {
  try {
    const task = await CalendarItem.findById(req.params.id);
    if (!task) {
      return res.status(404).json({ success: false, message: 'Task not found' });
    }

    const { title, description, date, startTime, completed, priority } = req.body;
    if (title !== undefined) task.title = title.trim();
    if (description !== undefined) task.description = description.trim();
    if (date !== undefined) task.date = new Date(date);
    if (startTime !== undefined) task.startTime = startTime.trim();
    if (completed !== undefined) task.completed = Boolean(completed);
    if (priority !== undefined) task.priority = priority;

    await task.save();

    return res.status(200).json({
      success: true,
      task,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

/**
 * @route   DELETE /api/calendar/tasks/:id
 * @desc    Delete a task
 * @access  Protected
 */
router.delete('/tasks/:id', requireAuth, async (req, res) => {
  try {
    await CalendarItem.findByIdAndDelete(req.params.id);
    return res.status(200).json({ success: true, message: 'Task deleted successfully' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;

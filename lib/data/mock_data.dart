import '../models/student.dart';
import '../models/event.dart';
import '../models/club.dart';
import '../models/bus.dart';
import '../models/lost_item.dart';
import '../models/message.dart';

class MockData {
  static final Student currentUser = Student(
    id: '1',
    name: 'Himakesh',
    email: 'himakesh@college.edu',
    department: 'Computer Science',
    year: '3rd Year',
    postsCount: 12,
    clubsCount: 5,
    eventsCount: 8,
  );

  static final List<Event> events = [
    Event(
      id: 'e1',
      title: 'Tech Talk 2026',
      date: DateTime.now().add(const Duration(days: 2)),
      timeString: '10:00 AM',
      endTimeString: '12:00 PM',
      location: 'AB2 Seminar Hall',
      description: 'Insightful tech talk on AI and the future of software development. Industry leaders share experiences on cutting-edge technologies.',
      organizer: 'Coding Club',
      availableSeats: 50,
      category: 'Technology',
      participantCount: 78,
      capacity: 150,
    ),
    Event(
      id: 'e2',
      title: 'Hackathon 3.0',
      date: DateTime.now().add(const Duration(days: 6)),
      timeString: '09:00 AM',
      endTimeString: '09:00 AM',
      location: 'Innovation Lab, Main Block',
      description: '24-hour hackathon to build innovative solutions for real-world campus problems. Teams of 2-4. Prizes worth 1,00,000+.',
      organizer: 'Tech Society',
      availableSeats: 20,
      category: 'Hackathon',
      participantCount: 124,
      capacity: 200,
      featured: true,
    ),
    Event(
      id: 'e3',
      title: 'Cultural Fest - Utsav 2026',
      date: DateTime.now().add(const Duration(days: 10)),
      timeString: '09:00 AM',
      endTimeString: '09:00 PM',
      location: 'Main Auditorium',
      description: 'Annual cultural festival featuring music, dance, art exhibitions, and dramatic performances. A celebration of campus talent.',
      organizer: 'Cultural Committee',
      availableSeats: 500,
      category: 'Cultural',
      participantCount: 342,
      capacity: 1000,
    ),
    Event(
      id: 'e4',
      title: 'AI and ML Workshop',
      date: DateTime.now().add(const Duration(days: 3)),
      timeString: '02:00 PM',
      endTimeString: '05:00 PM',
      location: 'Computer Lab 3, AB2',
      description: 'Hands-on workshop on practical machine learning using Python and TensorFlow. Train your own model. Bring your laptop.',
      organizer: 'AI Research Club',
      availableSeats: 15,
      category: 'Workshop',
      participantCount: 45,
      capacity: 60,
    ),
    Event(
      id: 'e5',
      title: 'Campus Career Fair 2026',
      date: DateTime.now().add(const Duration(days: 14)),
      timeString: '10:00 AM',
      endTimeString: '04:00 PM',
      location: 'Sports Complex Hall',
      description: 'Meet recruiters from 50+ top companies. Bring your resume and portfolio. On-spot interviews for pre-final and final year students.',
      organizer: 'Placement Cell',
      availableSeats: 0,
      category: 'Career',
      participantCount: 620,
      capacity: 800,
    ),
    Event(
      id: 'e6',
      title: 'Inter-College Cricket Tournament',
      date: DateTime.now().add(const Duration(days: 5)),
      timeString: '07:00 AM',
      endTimeString: '06:00 PM',
      location: 'University Cricket Ground',
      description: 'Annual inter-college cricket tournament. 16 teams, double elimination format. Entry for spectators is free.',
      organizer: 'Sports Committee',
      availableSeats: 300,
      category: 'Sports',
      participantCount: 210,
      capacity: 500,
    ),
    Event(
      id: 'e7',
      title: 'Robotics Club Showcase',
      date: DateTime.now().subtract(const Duration(days: 5)),
      timeString: '11:00 AM',
      endTimeString: '02:00 PM',
      location: 'Electronics Lab, AB3',
      description: 'Robotics Club presents semester projects including autonomous bots, line-followers, and drone demos. Open for all students.',
      organizer: 'Robotics Club',
      availableSeats: 0,
      category: 'Club',
      participantCount: 88,
      capacity: 100,
      status: 'past',
    ),
    Event(
      id: 'e8',
      title: 'DBMS Guest Lecture',
      date: DateTime.now().subtract(const Duration(days: 3)),
      timeString: '03:00 PM',
      endTimeString: '05:00 PM',
      location: 'Seminar Hall 1, AB1',
      description: 'Guest lecture by Dr. Suresh Rajan from IIT Madras on advanced database design patterns and NoSQL systems.',
      organizer: 'CSE Department',
      availableSeats: 0,
      category: 'Academic',
      participantCount: 145,
      capacity: 150,
      status: 'past',
    ),
  ];

  static final List<Club> clubs = [
    Club(
      id: 'c1',
      name: 'Coding Club',
      category: 'Technical',
      membersCount: 250,
      description: 'A community of passionate programmers and developers.',
    ),
    Club(
      id: 'c2',
      name: 'Photography Club',
      category: 'Creative',
      membersCount: 180,
      description: 'Capturing moments and exploring the art of photography.',
    ),
    Club(
      id: 'c3',
      name: 'Dance Club',
      category: 'Cultural',
      membersCount: 220,
      description: 'Expressing emotions through movement and rhythm.',
    ),
    Club(
      id: 'c4',
      name: 'Music Club',
      category: 'Cultural',
      membersCount: 150,
      description: 'For those who speak the universal language of music.',
    ),
  ];

  static final List<Bus> buses = [
    Bus(
      id: 'b1',
      name: 'Campus Shuttle 1',
      startTime: '08:10 AM',
      endTime: '08:18 AM',
      availableSeats: 10,
      startLocation: 'AB1',
      endLocation: 'AB3',
    ),
    Bus(
      id: 'b2',
      name: 'Campus Shuttle 3',
      startTime: '08:25 AM',
      endTime: '08:35 AM',
      availableSeats: 6,
      startLocation: 'AB1',
      endLocation: 'AB3',
    ),
    Bus(
      id: 'b3',
      name: 'Campus Express',
      startTime: '08:40 AM',
      endTime: '08:50 AM',
      availableSeats: 12,
      startLocation: 'AB1',
      endLocation: 'AB3',
    ),
  ];

  static final List<LostItem> lostItems = [
    LostItem(
      id: 'l1',
      name: 'Black Wallet',
      location: 'Library',
      timeAgo: 'Today, 11:30 AM',
      type: 'lost',
      description: 'Black leather wallet containing ID and some cash.',
    ),
    LostItem(
      id: 'l2',
      name: 'ID Card',
      location: 'AB2',
      timeAgo: 'Yesterday',
      type: 'lost',
      description: 'Student ID card for John Doe.',
    ),
    LostItem(
      id: 'l3',
      name: 'HP Laptop',
      location: 'Seminar Hall',
      timeAgo: '2 days ago',
      type: 'lost',
      description: 'Silver HP Pavilion laptop.',
    ),
    LostItem(
      id: 'l4',
      name: 'Keys',
      location: 'Canteen',
      timeAgo: '3 days ago',
      type: 'lost',
      description: 'Set of 3 keys with a blue keychain.',
    ),
  ];

  static final List<Message> messages = [
    Message(
      id: 'm1',
      senderName: 'Admin',
      lastMessage: 'Event updated',
      time: '10:30 AM',
      isUnread: true,
    ),
    Message(
      id: 'm2',
      senderName: 'Coding Club',
      lastMessage: 'Meeting at 5 PM',
      time: '09:15 AM',
    ),
    Message(
      id: 'm3',
      senderName: 'Rahul',
      lastMessage: 'Is the laptop found?',
      time: 'Yesterday',
    ),
    Message(
      id: 'm4',
      senderName: 'Anjali',
      lastMessage: 'Thanks!',
      time: 'Yesterday',
    ),
    Message(
      id: 'm5',
      senderName: 'Support',
      lastMessage: 'How can we help?',
      time: '2 days ago',
    ),
  ];

  static final List<Map<String, String>> news = [
    {
      'title': 'Annual Fest 2026',
      'subtitle': 'Registration is now open'
    },
    {
      'title': 'Placement Cell Update',
      'subtitle': 'New companies added this week'
    },
    {
      'title': 'Exam Schedule',
      'subtitle': 'Semester timetable released'
    },
  ];
}

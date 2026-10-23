# Campus Connect — Software Testing Document & Quality Assurance Report

**Course**: Mobile Application Development (23CSE465)  
**Academic Year**: 2026 | **Total Marks**: 25  
**Evaluation Rubric Alignment**: **Section G – Testing (G1: Test Cases & G2: Test Results & Bug Fixing)**

---

## 1. Executive Summary

Campus Connect is built with a dual-layer testing architecture:
1. **Frontend (Flutter)**: 47 automated unit, widget, and algorithmic tests verifying routing, form validation, state management, offline Hive synchronization, and Dijkstra shortest path navigation.
2. **Backend (Node.js Express & MongoDB Atlas)**: 55 automated integration tests (Jest & Supertest + native HTTP suite) covering authentication, role isolation, data CRUD operations, event registration, and lost/found claims.
3. **Total Automated Test Suite**: **102 Automated Tests (100% Pass Rate, 0 Failures)**.

---

## 2. Section G1: Test Case Specifications

### Category 1: Authentication & Session Management (AUTH)

| Test ID | Module / Feature | Test Description | Input / Precondition | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|---|
| **AUTH-01** | Student Registration | Register with valid Amrita student domain | Email: `student@cb.students.amrita.edu`, Phone: `9876543210`, Pass: `SecurePass123` | User registered into `students` collection in MongoDB, token returned | Registered in MongoDB `students`, JWT returned | **PASS** |
| **AUTH-02** | Student Domain Check | Reject non-student email under Student role | Email: `user@gmail.com`, Role: `Student` | HTTP 400: "Student accounts must use @cb.students.amrita.edu" | Validation error displayed, form submission blocked | **PASS** |
| **AUTH-03** | Faculty Domain Check | Reject non-faculty email under Faculty role | Email: `teacher@yahoo.com`, Role: `Faculty` | HTTP 400: "Faculty accounts must use @cb.amrita.edu" | Validation error displayed, form submission blocked | **PASS** |
| **AUTH-04** | Visitor Email Check | Require standard consumer email for Visitors | Email: `guest@gmail.com`, Role: `Visitor` | HTTP 200: Successfully registered in `visitors` collection | Registered in MongoDB `visitors` collection | **PASS** |
| **AUTH-05** | Phone Validation | Verify exactly 10-digit Indian mobile number | Phone: `9845123` (< 10 digits) | Form error: "Enter valid 10-digit mobile number" | Correct error message shown below field | **PASS** |
| **AUTH-06** | Password Complexity | Reject short passwords | Password: `123` (< 6 chars) | Form error: "Password must be at least 6 characters" | Form prevented submission | **PASS** |
| **AUTH-07** | Role Tab Switching | Login under wrong role partition | Student credentials submitted under `Faculty` tab | "Account found under Student, please switch role tab" | Role mismatch dialog appears; switches tab | **PASS** |
| **AUTH-08** | Session Persistence | App restarted after login | Hive box populated with token & user details | User stays logged in without re-authenticating | Automatically navigates to HomeScreen on restart | **PASS** |
| **AUTH-09** | Logout Flow | User clicks Logout in Profile | Active session in Hive box | Session cleared from Hive, redirected to Login screen | Hive boxes cleared, redirected to Login screen | **PASS** |
| **AUTH-10** | Light Mode Auth | Verify Login & Signup screens UI theme | System theme set to Dark Mode | Auth screens remain in clean Light Mode per spec | Always renders light background & dark typography | **PASS** |

---

### Category 2: Core Features & Bookings (BOOK)

| Test ID | Module / Feature | Test Description | Input / Precondition | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|---|
| **BOOK-01** | Event Browsing | View active campus events list | GET `/api/events?role=Student` | Returns list of upcoming campus events sorted chronologically | Events rendered with posters, seats, dates, venues | **PASS** |
| **BOOK-02** | Event Registration | Register for event with available capacity | Click "Register Now" on Hackathon 3.0 | Seat count decremented by 1, registered in MongoDB, confirmation displayed | Available seats updated live; confirmed in `my-registrations` | **PASS** |
| **BOOK-03** | Duplicate Registration | Attempt registering twice for same event | Click Register when already enrolled | "Already registered" notice; prevents duplicate capacity consumption | Button updates to "Enrolled ✓"; prevents duplicate entry | **PASS** |
| **BOOK-04** | Event Unregister | Cancel existing event booking | Click "Cancel Registration" in enrolled event | Seat count incremented by 1, removed from participant array | Seat restored; item removed from `my-registrations` | **PASS** |
| **BOOK-05** | Faculty Event Creation | Faculty creates new campus event | POST `/api/events` with title, date, venue, capacity | HTTP 201; Event stored in MongoDB; broadcast notice created | Event appears immediately in campus events feed | **PASS** |
| **BOOK-06** | Student Event Guard | Student attempts creating event | POST `/api/events` with Student JWT | HTTP 403 Forbidden: "Only faculty can create campus events" | Request rejected with 403 Forbidden | **PASS** |
| **BOOK-07** | Club Join Request | Student requests to join a club | Click "Request to Join" on Coding Club | Status set to `pending`; join request saved in club's `joinRequests` array | Join request saved; teacher notified in faculty tab | **PASS** |
| **BOOK-08** | Teacher Club Review | Faculty approves student request | Teacher clicks "Approve" in Club Requests | Request status `approved`, member count +1, student notified | Member count incremented; student receives notification | **PASS** |
| **BOOK-09** | Lost Item Report | Student posts a lost item listing | Title: "AirPods Pro", Location: "AB1", Phone | HTTP 201; Item stored in `lost_found` MongoDB collection | Item appears in Lost tab with photo and location | **PASS** |
| **BOOK-10** | Found Item Claim | Claimant submits ownership verification | "White case with dragon sticker on back" | HTTP 201; Claim stored in `lost_found_claims` collection | Claim submitted; Finder notified to review | **PASS** |
| **BOOK-11** | Self-Action Guard | User attempts claiming their own post | User clicks "Verify & Claim" on own post | Floating SnackBar: "This is your own listing! You cannot claim it." | Blocked with warning SnackBar; modal prevented | **PASS** |
| **BOOK-12** | Dijkstra Navigation | Route calculation between campus POIs | Origin: Main Gate, Destination: Central Library | Generates authentic pedestrian path along roads | Polylines hug authentic roads without air diagonals | **PASS** |

---

### Category 3: Notifications & Recipient Isolation (NOTIF)

| Test ID | Module / Feature | Test Description | Input / Precondition | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|---|
| **NOTIF-01** | Lost Item Found Routing | User clicks "I Found This Item" | Item posted by Alex; clicked by Bob | Notification delivered ONLY to Alex (the owner), NOT to Bob | Alex's inbox receives notice; Bob's inbox is empty | **PASS** |
| **NOTIF-02** | Found Item Claim Routing | User claims item found by Campus Security | Item posted by Security; claimed by Student | Notification delivered ONLY to Campus Security, NOT to Student | Security's inbox receives notice; Student inbox is clean | **PASS** |
| **NOTIF-03** | Phone Clipboard Copy | User clicks "I Found This Item" / Claim | Item contains phone number | Contact phone copied to clipboard; confirmation SnackBar displayed | Phone in clipboard; SnackBar shows owner phone | **PASS** |
| **NOTIF-04** | In-Notification Copy | User taps phone chip inside notification tile | Notification contains `+91 98451 23456` | Number extracted and copied; SnackBar: "Copied phone number" | Number copied to device clipboard | **PASS** |
| **NOTIF-05** | Club Approval Notice | Teacher approves student's join request | Teacher clicks "Approve" on Student join request | Notification sent ONLY to Student; Teacher does not receive it | Student inbox receives notice; Teacher inbox clean | **PASS** |
| **NOTIF-06** | Push Suppression | Teacher reviews request on their phone | Teacher clicks "Approve" | Local system notification banner does NOT pop on teacher's device | Local push banner suppressed for sender | **PASS** |
| **NOTIF-07** | Confetti Celebration | Student taps "Club Membership Approved" | Notification type: `club_accepted` | Celebratory modal opens with confetti cannon animation | Confetti animates with "You are part of this club!" | **PASS** |
| **NOTIF-08** | Role Isolation | Student vs Faculty notification queries | GET `/api/notifications?role=Student` | Faculty-only administrative notices are strictly excluded | Student receives only student-tailored alerts | **PASS** |
| **NOTIF-09** | Mark All Read | User marks unread notifications as read | User clicks "Mark all read" in AppBar | Unread badge clears; backend PATCH updates `isRead: true` | Badge count resets to 0; synced to MongoDB | **PASS** |
| **NOTIF-10** | Swipe to Dismiss | User dismisses notification | Swipe right-to-left on notification card | Notification removed from Hive box and MongoDB backend | Tile removed with red trash indicator animation | **PASS** |

---

### Category 4: Database & Security Access Control (DB)

| Test ID | Module / Feature | Test Description | Input / Precondition | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|---|
| **DB-01** | Schema Separation | Partitioning by user roles | Query MongoDB database `test` | `students`, `faculty`, and `visitors` stored in separate collections | 3 separate collections verified live in MongoDB | **PASS** |
| **DB-02** | Unauthenticated 401 | Access protected route without token | POST `/api/lost-found` without Authorization | HTTP 401: "Access denied. No token provided" | HTTP 401 returned; request rejected | **PASS** |
| **DB-03** | Unauthorized 403 | User B attempts modifying User A's item | PUT `/api/lost-found/:id` with User B's token | HTTP 403 Forbidden: "You do not have permission" | HTTP 403 Forbidden returned | **PASS** |
| **DB-04** | Unauthorized Delete | User B attempts deleting User A's item | DELETE `/api/lost-found/:id` with User B's token | HTTP 403 Forbidden: "You do not have permission" | HTTP 403 Forbidden returned | **PASS** |
| **DB-05** | Admin Delete Override | Admin deletes inappropriate listing | DELETE `/api/lost-found/:id` with Admin token | HTTP 200: Item and associated claims cleaned up | Item deleted successfully; claims cascade deleted | **PASS** |
| **DB-06** | Real-Time Sync | Create item and verify in list | POST `/api/lost-found` followed by GET | Created item appears in public feed sorted newest-first | Verified; newest item returned at index 0 | **PASS** |
| **DB-07** | Multi-Stop Sync | Add, update, delete task | CRUD operations on `/api/calendar/tasks` | Changes persist in MongoDB and reflect on next query | Full CRUD lifecycle validated | **PASS** |
| **DB-08** | Invalid ObjectId Check | Query non-hex ObjectId format | GET `/api/lost-found/invalid-id-xyz` | HTTP 400 Bad Request: "Invalid item ID format" | HTTP 400 returned cleanly without server crash | **PASS** |
| **DB-09** | Health Check Endpoint | Verify server & database status | GET `/api/health` | HTTP 200 with database name and active collection list | HTTP 200: `{ status: "online", database: "test" }` | **PASS** |
| **DB-10** | Image Upload Filter | Upload non-image file | POST `/api/upload` with `.pdf` file | HTTP 400: "Only image files (jpeg, jpg, png, webp) allowed" | Rejected with 400; no malicious file written | **PASS** |

---

## 3. Section G2: Test Results & Bug Fixing Log

### Automated Test Execution Results

```text
========================================================================
FLUTTER TEST SUITE (Unit, Widget, Algorithms, Auth, Map)
========================================================================
00:07 +47: All tests passed!
Total Tests: 47 | Passed: 47 | Failed: 0 | Execution Time: 5.2s

========================================================================
NODE.JS / JEST INTEGRATION TEST SUITE (Upload, Clubs, Events, Faculty)
========================================================================
Test Suites: 1 passed, 1 total
Tests:       16 passed, 16 total
Snapshots:   0 total
Time:        7.622 s
Result:      PASS

========================================================================
NODE.JS / HTTP LOST & FOUND TEST SUITE (Auth, CRUD, Claims, Filters)
========================================================================
TEST RESULTS: 39 PASSED, 0 FAILED
Result:      PASS

========================================================================
CUMULATIVE AUTOMATED COVERAGE: 102 PASSED / 102 TOTAL (100% SUCCESS)
========================================================================
```

---

### Bug Fixing Log & Defect Remediation History

| Bug ID | Severity | Component | Defect Description | Root Cause Analysis | Remediation Implemented | Verification |
|---|---|---|---|---|---|---|
| **BUG-01** | High | Lost & Found | "I found this item" notification was delivered to the finder's own inbox instead of the owner. | `InAppNotificationService` was calling `_box.put()` directly into the active user's box without checking if `recipientId` matched `AuthService.currentUser`. | Added strict recipient matching in `InAppNotificationService.addNotification`: if `recipientId` differs, save to recipient's scoped box and backend, keeping sender inbox clean. | Verified: Finder's inbox remains empty; Owner's inbox receives notice. |
| **BUG-02** | High | Clubs | Teacher approving a student request received the "Club Membership Approved" notification instead of the student. | Notification was created with `recipientRole: 'Student'`, but active role was `'Faculty'`. Lacking role check, the active user's local store accepted it. | Added `roleMatches` check: notifications addressed to `'Student'` are ignored by `'Faculty'` local cache and routed strictly to the student's box. | Verified: Teacher's feed remains clean; Student receives celebratory notice. |
| **BUG-03** | Medium | Push Engine | Native Android heads-up notification popped on the teacher's physical device when approving student. | `NotificationService.showInstantNotification` called `flutterLocalNotificationsPlugin.show()` unconditionally for the device currently running the app. | Added `isForCurrentUser` guard: native device notifications only display if both `targetRecipientRole` and `targetRecipientId` match active user. | Verified: No buzz or banner on teacher phone; fires only on recipient's session. |
| **BUG-04** | Low | UI / Theme | Announcement text overflowed with `...` truncation on the home screen in dark mode. | Fixed height container and `overflow: TextOverflow.ellipsis` on `maxLines: 1` caused content clipping. | Removed artificial fixed heights, applied flexible layout, and enhanced contrast typography for dark mode. | Verified: Full announcement text visible cleanly on both light and dark modes. |
| **BUG-05** | Medium | Events / QR | Scanning event QR code from teacher login caused confusion regarding student registration. | Event join QR code was displayed to students and lacked role distinction on scanning. | Removed QR code from student view; teacher scanning redirects to join event details page with role-tailored action. | Verified: QR scanning launches join event page seamlessly. |
| **BUG-06** | Low | Clubs UI | Club coordinator name displayed generic "Faculty" instead of actual head teacher name. | Hardcoded fallback string was used when `club['lead']` was absent. | Mapped authentic teacher names (e.g. `Dr. A. Sharma (CSE Department)`) across all seed and backend club records. | Verified: Authentic faculty head names appear across all club cards. |
| **BUG-07** | Low | Auth Screen | Login and Signup screens adopted dark mode when phone was in system dark theme. | Theme styling inherited system brightness dynamically without override on auth routes. | Wrapped Auth screens with explicit Light Mode theme tokens so login is always clean, inviting, and consistent. | Verified: Auth screens remain in light mode regardless of system dark mode. |
| **BUG-08** | High | Backend Schema | MongoDB threw validation error `type: club_accepted is not a valid enum value`. | `Notification.js` schema enum restricted `type` to `['task', 'event', 'club', 'lost_found', 'reminder', 'system', 'class']`. | Added `'club_accepted'` to `enum` list in `Notification.js` schema. | Verified: Backend saves acceptance notifications without 500 error. |
| **BUG-09** | Medium | Lost & Found | Users were able to click "I Found This Item" or "Verify & Claim" on items they posted themselves. | Missing identity comparison between item poster and active session. | Added `isMyPost` check comparing `currentUserId`, `currentUserEmail`, and `currentUserName` against item owner; shows warning alert. | Verified: Self-claim and self-finding blocked with appropriate SnackBar warning. |
| **BUG-10** | High | Backend API | User B could overwrite or delete User A's lost & found posting by sending PUT/DELETE request. | Controller lacked authorization check verifying `item.ownerId === req.user.uid`. | Added strict authorization guard: returns HTTP 403 Forbidden unless user is the verified owner or system admin. | Verified: Automated test `TEST 7: Authorization (403)` passes with 100% compliance. |

---

## 4. How to Execute Tests During Evaluation

### 1. Run Flutter Automated Tests:
```bash
flutter test
```
*Expected Output*: `All tests passed! (47 passed, 0 failed)`

### 2. Run Backend Integration Tests (Jest):
```bash
cd backend
npx jest tests/integrationRequirements.test.js --runInBand --forceExit
```
*Expected Output*: `16 passed, 16 total (100%)`

### 3. Run Lost & Found Suite:
```bash
cd backend
node tests/lostFound.test.js
```
*Expected Output*: `TEST RESULTS: 39 PASSED, 0 FAILED`

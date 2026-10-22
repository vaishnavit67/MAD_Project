# Campus Connect Backend (Node.js + Express + MongoDB)

REST API backend for the Campus Connect MAD Flutter application. Connects to MongoDB (Local or MongoDB Atlas Cloud) and maintains role-partitioned collections ("tables") for **faculty**, **students**, and **visitors**.

---

## 📁 Architecture Overview

```
backend/
├── models/
│   ├── Faculty.js       # Mongoose model for 'faculty' collection
│   ├── Student.js       # Mongoose model for 'students' collection
│   └── Visitor.js       # Mongoose model for 'visitors' collection
├── middleware/
│   └── validator.js     # Role domain & format validation
├── routes/
│   └── authRoutes.js    # /signup, /login, /users/:role, /stats endpoints
├── .env                 # Environment variables (PORT, MONGODB_URI, JWT_SECRET)
├── .env.example         # Template for environment variables
├── package.json         # Node.js dependencies (express, mongoose, bcryptjs, etc.)
└── server.js            # Main Express server entry point & MongoDB connection
```

---

## 🚀 Quick Start

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Configure MongoDB in `.env`
Open `backend/.env` and set your MongoDB URI:

- **Local MongoDB**:
  ```env
  PORT=5000
  MONGODB_URI=mongodb://127.0.0.1:27017/campus_connect
  JWT_SECRET=campus_connect_jwt_secret_token_2026
  ```

- **MongoDB Atlas Cloud**:
  ```env
  PORT=5000
  MONGODB_URI=mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/campus_connect?retryWrites=true&w=majority
  JWT_SECRET=campus_connect_jwt_secret_token_2026
  ```

### 3. Run Server
```bash
npm start
```
The server will start at `http://localhost:5000` and automatically create the collections and seed initial demo accounts.

---

## 📡 API Endpoints

### 1. Health Check
- **`GET /api/health`**
- Returns server status, MongoDB connection state, and active collections.

### 2. User Registration (Signup)
- **`POST /api/auth/signup`**
- **Body**:
  ```json
  {
    "name": "Amrita Student",
    "email": "student@cb.students.amrita.edu",
    "phone": "9876543210",
    "rollNumber": "CB.EN.U4CSE21001",
    "password": "password123",
    "role": "Student"
  }
  ```
- **Validation**:
  - `Student` ➔ Must use `@cb.students.amrita.edu` (saved into `students` table)
  - `Faculty` ➔ Must use `@cb.amrita.edu` (saved into `faculty` table)
  - `Visitor` ➔ Must use `@gmail.com` (saved into `visitors` table)
  - `phone` ➔ 10 digits starting with 6-9
  - `password` ➔ At least 6 characters (hashed with bcrypt)
  - Duplicate email and phone checks across all tables.

### 3. User Login
- **`POST /api/auth/login`**
- **Body**:
  ```json
  {
    "identity": "student@cb.students.amrita.edu",
    "password": "password123",
    "role": "Student"
  }
  ```
- Supports login with role email or 10-digit mobile number.
- Cross-role guard: If user registered as Student tries to log in under Faculty tab, returns an informative role-switch message.

### 4. Role User List & Stats
- **`GET /api/auth/users/students`** (or `faculty`, `visitors`)
- **`GET /api/auth/stats`** (returns count of users in each table)

# 🎓 UniMentor

UniMentor is a mobile mentoring platform developed as a **Final Year Project** to help **Universiti Kuala Lumpur (UniKL) students** connect with mentors, manage mentoring activities, communicate, and access learning resources in one platform.

## 📱 Overview

UniMentor provides a centralized platform where students can participate in mentoring activities through mentor-mentee matching, communication, booking sessions, learning materials, reviews, and related academic activities.

The application supports both **mentors and mentees**, providing different functionalities based on their roles.

## ✨ Key Features

* 👤 **Mentor & Mentee Registration**

  * Role-based account registration
  * UniKL student email restriction

* 🔍 **Mentor-Mentee Matching**

  * Helps mentees discover suitable mentors based on their needs and interests

* 💬 **Chat**

  * Communication between mentors and mentees

* 📅 **Mentoring Session Booking**

  * Book mentoring sessions with selected mentors
  * Supports online and physical mentoring sessions

* 💳 **Booking Management**

  * Supports paid mentoring bookings

* 📚 **Learning Materials**

  * Access and manage mentoring-related materials

* ⭐ **Ratings & Reviews**

  * Allows users to provide feedback after mentoring sessions

* 🏆 **Co-Curriculum Certificate**

  * Supports certificate-related mentoring activities

* 📝 **Reports**

  * Provides reporting functionality for mentoring activities

## 🛠️ Technologies Used

| Technology                  | Purpose                                |
| --------------------------- | -------------------------------------- |
| **Flutter**                 | Mobile application development         |
| **Dart**                    | Application programming language       |
| **Firebase Authentication** | User authentication                    |
| **Cloud Firestore**         | Database and real-time data management |
| **Firebase Storage**        | File and document storage              |
| **Android Studio**          | Android development and testing        |
| **Visual Studio Code**      | Application development                |

## 🔐 Authentication & Access

UniMentor is designed specifically for the **UniKL student community**.

During registration, users are required to provide an email address using the UniKL student email domain:

```text
@s.unikl.edu.my
```

This domain restriction was implemented to limit registration to users using the UniKL student email format.

## 🗄️ Firebase Integration

UniMentor integrates several Firebase services:

* **Firebase Authentication** — user authentication and account management
* **Cloud Firestore** — application database and real-time data management
* **Firebase Storage** — storage for uploaded files and learning materials

## 👩‍💻 Project Contribution

UniMentor was developed as a Final Year Project as part of the Bachelor of Software Engineering (Hons) programme at Universiti Kuala Lumpur (UniKL MIIT).

I was responsible for the end-to-end development of the application, including:

* 📱 Mobile application development using Flutter and Dart
* 🎨 User interface and user experience implementation
* 🔐 Authentication and role-based access
* 🔥 Firebase Authentication integration
* 🗄️ Cloud Firestore database integration
* 📁 Firebase Storage integration
* 🔍 Mentor-mentee matching functionality
* 💬 Chat functionality
* 📅 Booking and session management
* 💳 Online and physical mentoring booking functionality
* 📚 Learning materials functionality
* ⭐ Ratings and reviews
* 🏆 Co-curriculum certificate functionality
* 🐛 Testing, debugging, and troubleshooting


## 📸 Application Screenshots

### 🔐 Authentication

<p align="center">
  <img src="screenshots/login.png" width="280">
</p>

### 🏠 Mentee Dashboard & Homepage

<p align="center">
  <img src="screenshots/mentee%20-%20dashboard.png" width="280">
  <img src="screenshots/mentee%20-%20homepage.png" width="280">
</p>

### 🔍 Mentor & Mentee Features

<p align="center">
  <img src="screenshots/mentor's%20profile.png" width="280">
  <img src="screenshots/mentor%20-%20homepage.png" width="280">
</p>

### 💬 Chat

<p align="center">
  <img src="screenshots/chat.png" width="280">
</p>

### 📅 Booking

<p align="center">
  <img src="screenshots/mentee%20-%20booking.png" width="280">
</p>

### 🏆 Mentor Co-Curricular

<p align="center">
  <img src="screenshots/mentor%20-%20cocurricular.png" width="280">
</p>

### 💰 Mentor Wallet

<p align="center">
  <img src="screenshots/mentor%20-%20wallet.png" width="280">
</p>

### 💬 Forum

<p align="center">
  <img src="screenshots/open%20forum.png" width="280">
</p>


## 🚀 Getting Started

### Prerequisites

Before running the project, make sure you have:

* Flutter SDK
* Dart SDK
* Android Studio or Visual Studio Code
* Android Emulator or Android device
* A configured Firebase project

### Installation

Clone the repository:

```bash
git clone https://github.com/fashahellal/UniMentor.git
```

Navigate to the project directory:

```bash
cd UniMentor
```

Install the required dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

### Firebase Configuration

The project requires Firebase configuration to run correctly.

Firebase services used by the application include:

* Firebase Authentication
* Cloud Firestore
* Firebase Storage

## 🎓 Academic Project

**Bachelor of Software Engineering (Hons)**
**Universiti Kuala Lumpur (UniKL MIIT)**

**Final Year Project**

Expected Graduation: **March 2027**

---

⭐ *UniMentor — Connecting students through meaningful mentoring experiences.*

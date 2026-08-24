# ProTalk 🎙️
### Professional Communication Simulator

> **AI-powered English communication and interview practice for students and aspiring professionals.**

ProTalk is a Flutter-based mobile application designed to help students improve **English communication, speaking confidence, professional communication, and interview readiness** through interactive AI-powered practice sessions.

The application combines conversational practice, simulated interviews, voice interaction, personalized AI responses, session history, and performance feedback in a single training platform.

---

## 📌 Problem Statement

Many students have strong technical knowledge but struggle to communicate their thoughts clearly and confidently.

Common difficulties include:

- Hesitation while speaking English
- Lack of speaking confidence
- Poor pronunciation and fluency
- Difficulty forming sentences
- Limited vocabulary
- Fear of interviews
- Difficulty answering interview questions appropriately
- Lack of realistic interview practice
- Limited access to personalized feedback
- Difficulty handling real-world professional communication

Traditional preparation methods often provide limited opportunities for students to actually **speak, practice, make mistakes, and receive personalized feedback**.

ProTalk addresses this gap by providing an interactive environment where users can practice communication and interview scenarios with an AI-based simulator.

---

## 🎯 Project Objective

The primary objective of ProTalk is to help users become:

- More confident speakers
- More fluent in English
- Better at professional communication
- Better prepared for interviews
- More comfortable answering questions
- More aware of their communication weaknesses
- More capable of improving through repeated practice

---

# ✨ Core Modules

ProTalk is centered around two major training modules.

## 1. 🎤 Interview Preparation

The Interview Preparation module provides a simulated interview environment.

Users can configure their practice session according to their target interview.

### Configuration

- **Interview Type**
  - HR
  - Technical
  - HR + Technical
  - Internship / Placement

- **Job Role**
  - Software Developer
  - Data Analyst
  - Other roles

- **Skills / Technologies**
  - Flutter
  - Java
  - Python
  - SQL
  - Other technologies

- **Education / Branch**
  - CSE
  - IT
  - AI/ML
  - ECE
  - Other branches

- **Experience Level**
  - Fresher
  - 0–1 Year
  - 1–3 Years
  - Experienced

- **Difficulty**
  - Easy
  - Medium
  - Hard

- **Interview Focus**
  - Technical
  - HR
  - Communication
  - Problem Solving
  - Mixed

- **Target Company**
  - Optional company-specific preparation

The interview experience is intended to simulate realistic interview communication and evaluate the user's responses.

---

## 2. 💬 English Conversation

The English Conversation module helps users practice everyday and professional English communication.

### Conversation Topics

- Daily Life
- College Life
- Friends & Social Life
- Travel
- Technology
- Job & Career
- Interview
- Business
- Random Conversation
- Custom Topic

### Difficulty Levels

- Beginner
- Intermediate
- Advanced

### AI Personality

- Friendly
- Professional
- Casual
- Interviewer
- Teacher
- Motivational

### Conversation Language

- English Only
- English + Hindi
- English + Gujarati

### Correction Mode

- Correct Every Mistake
- Correct Important Mistakes
- Don't Interrupt, Give Feedback Later
- Feedback at the End

### Conversation Style

- Normal Conversation
- Ask Me Questions
- Debate
- Role Play
- Storytelling
- Situation Based

### Conversation Goals

- Daily English
- Speaking Confidence
- College Communication
- Interview Communication
- Professional Communication
- Presentation Skills
- Group Discussion
- Public Speaking

### AI Response Style

- **Short & Simple** — easy-to-understand responses
- **Natural Conversation** — friendly and human-like responses
- **Detailed** — explanations and examples
- **Professional** — workplace-style English

---

# 🗣️ Voice Interaction

ProTalk supports voice-based communication to make practice more natural.

The application can use:

**User Voice → Speech-to-Text → AI → Text Response → Text-to-Speech**

### Speech Input

The application uses audio recording and speech-to-text processing so users can answer questions by speaking instead of typing.

### Text-to-Speech

AI responses can be spoken back to the user using configurable system TTS voices.

Users can configure:

- Voice gender
- Speech speed
- Voice volume

This allows the conversation to feel closer to a real speaking session.

---

# 🔄 Interaction Modes

## Manual Mode

Users can control the conversation manually.

Typical flow:

1. Read/listen to the AI response
2. Tap the microphone
3. Speak
4. Stop recording
5. Receive transcription
6. Submit the response
7. Receive the AI response

Text input can also be used where supported.

## Live Auto Mode

The application also supports a hands-free interaction flow.

The intended interaction is:

```text
AI speaks
   ↓
AI finishes speaking
   ↓
Listening starts automatically
   ↓
User speaks
   ↓
Silence detected
   ↓
Recording stops
   ↓
Speech converted to text
   ↓
AI generates response
   ↓
AI speaks
   ↓
Repeat
```

Silence detection is used to determine when the user's spoken response has ended.

---

# 🤖 AI Integration

ProTalk is designed around AI-powered conversation and evaluation.

The project uses **Groq services** for AI processing and speech-to-text functionality.

The application architecture separates AI functionality into dedicated service classes rather than placing API logic directly inside UI screens.

This keeps the application easier to maintain and extend.

### AI Responsibilities

The AI layer can be used for:

- Interview question generation
- Conversational responses
- Context-aware interaction
- Communication practice
- Interview evaluation
- Performance feedback
- Improvement suggestions

---

# 📊 Feedback & Performance Review

One of ProTalk's important features is post-session analysis.

After sufficient conversation data is available, the application can generate a performance review.

## Interview Review

The interview review can evaluate areas such as:

- Overall Score
- Confidence
- Communication Skills
- Answer Quality
- Technical Knowledge
- Problem-Solving Skills
- Answer Structure
- English Fluency
- Professionalism
- Interview Readiness
- Response Relevance

## English Communication Review

English practice can evaluate:

- Overall Score
- English Fluency
- Grammar
- Vocabulary
- Pronunciation
- Confidence
- Sentence Formation
- Speaking Clarity
- Comprehension
- Conversation Skills
- Filler Word Control

---

## 💡 Improvement Feedback

A review is not limited to scores.

The application can provide:

### Key Strengths
Areas where the user performed well.

### Areas to Improve
Specific weaknesses identified during the session.

### Improvement Tips
Actionable suggestions that users can apply during future practice sessions.

This creates a continuous improvement cycle:

```text
Practice
   ↓
Conversation / Interview
   ↓
Analysis
   ↓
Feedback
   ↓
Identify Weaknesses
   ↓
Practice Again
   ↓
Improvement
```

---

# 📴 Local Fallback Analytics

ProTalk is designed with a local fallback approach for analytics.

If network-based review processing is unavailable or times out, the application can use local analysis based on available conversation data.

Possible signals include:

- Word count
- Vocabulary richness
- Filler-word usage
- Conversation data

This allows the application to provide useful feedback even when the external review service cannot complete the request.

---

# 💾 Offline Data & Session Management

ProTalk uses a local SQLite database through `sqflite`.

The database is used to persist application data such as:

- Chat sessions
- Chat messages
- Session configurations
- Session reports
- Conversation history

This allows users to retain their previous practice sessions and review results locally.

---

# 🕘 Conversation History

Previous sessions can be stored locally and reopened later.

A session contains information such as:

- Session identifier
- Session title
- Module
- Creation time
- Last update time
- Messages
- Session configuration
- Performance report

This allows users to continue or review previous practice sessions instead of starting from scratch every time.

---

# ↩️ Conversation Backtracking

ProTalk supports conversation backtracking.

Users can select an earlier message and remove that message together with subsequent responses.

This makes it possible to restart the conversation from a previous point.

Example:

```text
Message 1
Message 2
Message 3  ← Select
Message 4
Message 5
```

After backtracking:

```text
Message 1
Message 2
```

The user can then continue the conversation again from that point.

---

# ⚙️ Settings

The Settings area provides application-level controls.

## Voice Settings

- Voice volume
- Voice gender
- Speech speed

## Theme

- Light mode
- Dark mode

## Other Settings

- Notifications
- About
- Data & Privacy

---

# 🏗️ Application Architecture

ProTalk follows a modular Flutter architecture using **GetX**.

GetX is used for:

- State management
- Dependency injection
- Navigation
- Controller lifecycle management
- Reactive UI updates

The project separates UI, business logic, services, models, and application configuration.

### High-Level Architecture

```text
┌──────────────────────────────┐
│          Flutter UI          │
│          Screens             │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│        GetX Controllers       │
│     Application Business      │
│            Logic              │
└──────────────┬───────────────┘
               │
       ┌───────┼────────┐
       ▼       ▼        ▼
   API Layer  DB Layer  Voice Layer
       │       │        │
       ▼       ▼        ▼
     Groq    SQLite    STT / TTS
```

---

# 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| **Flutter** | Cross-platform mobile application development |
| **Dart** | Application programming language |
| **GetX** | State management, routing and dependency injection |
| **SQLite / sqflite** | Local persistent storage |
| **Groq API** | AI processing |
| **Groq Whisper** | Speech-to-text |
| **http** | Network/API communication |
| **record** | Audio recording |
| **flutter_tts** | Text-to-speech |
| **shared_preferences** | Lightweight local preferences |
| **Material 3** | Application UI foundation |

---

# 📁 Project Structure

```text
lib/
│
├── bindings/
│   └── app_bindings.dart
│
├── controllers/
│   ├── chat_controller.dart
│   ├── login_controller.dart
│   └── review_controller.dart
│
├── core/
│   ├── constants/
│   ├── middleware/
│   └── theme/
│
├── models/
│   ├── chat_message.dart
│   └── session_report.dart
│
├── routes/
│   ├── app_routes.dart
│   └── routes.dart
│
├── screens/
│   ├── chat_screen.dart
│   ├── login_screen.dart
│   ├── review_screen.dart
│   └── session_selection_screen.dart
│
├── services/
│   ├── api/
│   ├── database/
│   ├── listen/
│   ├── theme/
│   └── voice/
│
└── widgets/
```

### Folder Responsibilities

**`bindings/`**  
Contains GetX dependency bindings and controller initialization.

**`controllers/`**  
Contains application business logic and reactive state.

**`core/`**  
Contains global constants, middleware, theme configuration, and application-level styling.

**`models/`**  
Contains structured data models.

**`routes/`**  
Contains route definitions and navigation configuration.

**`screens/`**  
Contains the main application UI screens.

**`services/`**  
Contains external API, database, audio, theme, and TTS functionality.

**`widgets/`**  
Contains reusable UI components.

---

# 🗃️ Data Model

The application maintains four primary categories of local session data.

```text
Chat Session
    │
    ├── Chat Messages
    │
    ├── Session Configuration
    │
    └── Session Report
```

Conceptually:

```text
chat_sessions
      │
      ├─────────────── chat_messages
      │
      ├─────────────── session_configs
      │
      └─────────────── session_reports
```

This structure keeps session data organized and makes it possible to restore conversations and their corresponding configuration and review information.

---

# 🔐 Configuration

External credentials and configurable values should be kept outside the application source code.

The project uses environment configuration for values such as API credentials and authentication configuration.

Example:

```env
GROQ_API_KEY=your_groq_api_key
GROQ_API_AI_KEY=your_groq_api_key
GROQ_MODEL=your_model_name

AUTH_EMAIL=your_email
AUTH_PHONE=your_phone
AUTH_PASSWORD=your_password
```

> **Security:** Never commit real API keys, passwords, or other secrets to a public Git repository.

Add `.env` to `.gitignore` when it contains sensitive credentials.

---

# 🚀 Getting Started

## Prerequisites

Install and configure:

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Android emulator or physical Android device

For iOS development, macOS with Xcode is required.

---

## 1. Clone the Repository

```bash
git clone https://github.com/valaprashant97/protalk.git
cd protalk
```

---

## 2. Install Dependencies

```bash
flutter pub get
```

---

## 3. Configure Environment

Create the required environment configuration file and add your API credentials and application configuration.

Do not use real credentials directly inside source files.

---

## 4. Check Flutter Setup

```bash
flutter doctor
```

Resolve any environment or device issues reported by Flutter.

---

## 5. Run the Application

```bash
flutter run
```

For a specific connected device:

```bash
flutter devices
flutter run -d <device-id>
```

---

# 📦 Build

## Android

Build a release APK:

```bash
flutter build apk --release
```

Build an Android App Bundle:

```bash
flutter build appbundle --release
```

## iOS

```bash
flutter build ipa --release
```

---

# 🧪 Development Workflow

A typical development workflow is:

```text
Configure Session
       ↓
Select Training Module
       ↓
Start Practice
       ↓
Voice / Text Interaction
       ↓
AI Response
       ↓
Continue Conversation
       ↓
Complete Session
       ↓
Generate Review
       ↓
Analyze Performance
       ↓
Practice Again
```

---

# 🎓 Target Users

ProTalk is primarily designed for:

- College students
- Freshers
- Internship applicants
- Placement candidates
- Job seekers
- Students improving spoken English
- Users preparing for technical interviews
- Users preparing for HR interviews
- Users who want to improve professional communication

---

# 🌟 Why ProTalk?

ProTalk brings several preparation activities into one application:

**English Practice + Interview Simulation + Voice Interaction + AI Feedback + Session History**

Instead of only reading interview questions or studying communication theory, users can actively practice communicating.

The platform focuses on a simple principle:

> **Practice → Analyze → Improve → Practice Again**

---

# 🔮 Future Scope

Potential future improvements include:

- More AI model providers
- More speech-to-text providers
- Advanced pronunciation analysis
- Detailed speaking analytics
- Personalized learning plans
- Progress dashboards
- Performance history and comparison
- More interview categories
- Company-specific interview simulations
- Additional regional language support
- Cloud synchronization
- User accounts and cross-device history
- Advanced voice activity detection
- More realistic interviewer personalities

---

# 👨‍💻 Project Information

**Project:** ProTalk  
**Type:** AI-powered Professional Communication Simulator  
**Platform:** Flutter Mobile Application  
**Primary Language:** Dart  
**Purpose:** English communication and interview preparation

---

# 📄 Project Documentation

The project documentation defines the application around two major training areas:

- **English Conversation**
- **Interview Preparation**

The English Conversation module provides configurable topics, difficulty, AI personality, language, correction mode, conversation style, goals, and response style.

The Interview Preparation module defines interview type, job role, technologies, education/branch, experience level, difficulty, interview focus, and optional target company. 

The broader project specification identifies the main application areas as Login, Module Selection, Feedback & Review, Chat, and Settings, including voice controls, themes, notifications, About, and Data & Privacy.

---

# 📜 License

This project is currently intended as an academic/project application.

Add the appropriate open-source license here if the project is later published for public reuse.

---

## ⭐ ProTalk

**Build confidence. Practice communication. Prepare for the real world.**


----

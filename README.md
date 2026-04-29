# 🩺 Rafiq — Your Personal AI Health Assistant

> **Rafiq** (رفيق) means *companion* in Arabic. This app is your intelligent, always-available medical companion — helping you manage medications, understand your health, and never miss a dose.

---

## 🧩 The Problem It Solves

Managing medications is harder than it sounds. Patients with chronic conditions often juggle **multiple prescriptions**, complex dosage schedules, drug interactions, and follow-up appointments — all without professional guidance between visits.

Common pitfalls:
- Forgetting to take medications at the right time
- Taking medications in the wrong order (e.g., food interactions)
- Not understanding what a prescription says
- No visibility into adherence over time
- No accessible channel to ask quick health questions

**Rafiq** solves all of this in one beautifully designed Flutter app.

---

## ✨ Core Features

### 💊 Smart Medication Management
- Add medications **manually** or by **scanning a prescription** (camera or gallery)
- Store medication name, active ingredient, and dosage
- Set multiple **alarm times** per medication and pick specific **days of the week**
- AI-generated **usage instructions** displayed inline on each card

### 🤖 AI Schedule Optimizer
- Tap **"AI Suggest"** and Gemini AI analyzes all your medications together
- Returns a conflict-free, optimized daily schedule
- Takes into account drug interactions and food-timing guidelines
- Preview the AI suggestion before accepting it

### 📊 Dashboard & Daily Tracking
- Personalized greeting with the patient's name and today's date
- **Next dose card** — always know what's coming up next
- Full chronological **today's schedule** with visual dose status:
  - ✅ Taken
  - ⚠️ Missed
  - 🕐 Upcoming
- Tap any dose time to **log it as taken** with a confirmation dialog
- Pull-to-refresh for real-time sync

### 📋 Daily Health Report
- AI-generated **daily health advice** based on your medication regimen
- View full daily report with a dedicated floating action button
- Advice rendered in rich Markdown format

### 💬 AI Chat Assistant
- Chat freely with an AI health assistant
- Persistent conversation history loaded on launch
- Animated typing indicator while the AI is responding
- Fully supports both **English** and **Arabic** with RTL layout

### 🏥 Medical Record
- Manage your personal medical profile
- Create a new profile (POST) or update existing one (PATCH)
- Supports creating profile for new users seamlessly

### ⚙️ Settings
- Language toggle: **Arabic / English** (full RTL support)
- Display authenticated user email
- Logout functionality

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x (Dart) |
| **State Management** | Riverpod 3 |
| **Navigation** | go_router |
| **Localization** | easy_localization (AR / EN) |
| **Networking** | http + Dio |
| **Secure Storage** | flutter_secure_storage |
| **Camera / Gallery** | image_picker, camera |
| **Markdown Rendering** | flutter_markdown |
| **UI Extras** | shimmer, flutter_svg |
| **AI Backend** | Gemini AI (via FastAPI backend) |

---

## 🚀 Running the App

### Prerequisites
- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android Studio / VS Code with Flutter extension
- A running instance of the [Rafiq Backend](https://github.com/) (FastAPI + Supabase)

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/your-username/rafiq_frontend.git
cd rafiq_frontend

# 2. Install dependencies
flutter pub get

# 3. Generate app icons
dart run flutter_launcher_icons

# 4. Run the app
flutter run
```

### Environment
The app connects to the Rafiq FastAPI backend. Make sure the base URL is correctly configured in the services layer before running.

---

## 📱 App Structure

```
lib/
├── core/
│   └── themes/           # App colors and theme tokens
├── features/
│   ├── auth/             # Login & registration screens
│   ├── chat/             # AI chat interface
│   ├── dashboard/        # Home dashboard + daily report
│   ├── medical_record/   # Patient medical profile
│   ├── pharmacy/         # Medication management + AI scheduling
│   └── settings/         # Language, account, logout
├── models/               # Data models (Medication, ChatMessage, etc.)
├── providers/            # Global Riverpod providers
├── services/             # API service classes
└── main.dart
```

---

## 🌍 Localization

Rafiq fully supports **Arabic (AR)** and **English (EN)** with proper RTL/LTR layout switching. Translation files are located in:

```
assets/translations/
├── ar.json
└── en.json
```

---

## 🔒 Security

- Authentication tokens stored securely using `flutter_secure_storage`
- All API calls authenticated via JWT Bearer tokens
- Passwords never stored in plain text

---

## 📸 Screenshots

> Coming soon — run the app and experience it yourself!

---

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

---

## 📄 License

This project is licensed under the MIT License.

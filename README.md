# Money Pilot 💰 - Smart AI Expense Tracker

**Money Pilot** is a modern, voice-powered personal finance tracker built with **Flutter** and **Google Gemini AI**.  
Track your daily income, expenses, and loans by simply speaking naturally in **English** or **Bangla**.

## ✨ Key Features

### 🎙️ AI Voice Interaction
- **Natural Language Processing**: Uses `SpeechToText` + **Google Gemini AI** to understand your speech
- **Smart Categorization**: Automatically detects Income/Expense, extracts Amount, and assigns Categories
- **Multi-Language Support**: Works in **English** and **Bangla** (`bn_BD`)
- **Robust Error Handling**: Auto-detects silence, timeouts, and API errors with helpful feedback
- **Preprocessing Layer**: Handles complex sentence structures and filler words for better accuracy.

> [!TIP]
> Just tap the microphone and say: *"I spent 500 taka on groceries"* or *"পাঁচশ টাকা বাজার"*

### 🧠 Smart Learning Loop
- **Correction Memory**: The app learns from your edits. If you change a category (e.g., "Netflix" from *Bills* to *Entertainment*), the app remembers this preference for future transactions.
- **Rule-Based Overrides**: Deterministic rules for common keywords (e.g., "Rickshaw" -> Transport) ensure speed and consistency.

### 📊 Dashboard & Analytics
- **Spending Trends**: Visual line chart with Week/Month toggle filters
- **Quick Stats**: Daily average spending and maximum single expense
- **Monthly Cycle**: Dashboard auto-resets monthly while preserving full history
- **Balance Overview**: Real-time total balance with income/expense breakdown

### 💸 Income Management
- **Salary Tracking**: Log monthly salary, bonuses, and other income
- **Remaining Balance**: See how much budget is left for the month
- **Dedicated Income Screen**: Clean interface for adding income transactions

### 🤝 Dual Loan Tracking
- **Given Loans**: Track money you lent to others (Assets)
- **Taken Loans**: Track money you borrowed (Liabilities)
- **Settlement**: Mark loans as paid/repaid
- **Balance Impact**: Loans correctly affect your cash position

### 🧠 AI Money Coach
- **Financial Insights**: Get personalized feedback on your spending habits
- **Good Job Highlights**: Positive reinforcement for smart financial decisions
- **Smart Tips**: Actionable advice to save money based on your data
- **On-Demand Analysis**: Tap "Analyze" to get fresh insights

### 🔔 Notification System
- **In-App Notification Center**: Bell icon with unread count badge
- **Budget Alerts**: Get notified when spending exceeds thresholds
- **Loan Reminders**: Set reminders for loan repayments
- **Scheduled Notifications**: System notifications for important alerts
- **Swipe to Delete**: Easy notification management

### 🔒 Data Privacy & Storage
- **Offline-First**: All data stored locally using **SQLite**
- **Secure Keys**: API Key stored locally in `SharedPreferences`
- **No Cloud Sync**: Your financial data never leaves your device

### 🎨 Modern UI/UX
- **Clean Design**: Premium, modern interface with smooth animations
- **Dual Input**: Voice (FAB) or Manual Entry (Quick Action buttons)
- **Instant Localization**: Toggle between English/Bangla
- **Dark Mode Ready**: System-aware theming
- **Modular Architecture**: Clean, refactored codebase for scalability.

---

## 🚀 Getting Started

### Prerequisites
- A **Google Gemini API Key** ([Get one here](https://aistudio.google.com/app/apikey))
- Internet connection (for AI processing)
- Microphone permission enabled

### Installation

#### Option 1: Install APK (Android)
1. Download the latest APK from [Releases](https://github.com/Iftekhar-Tasnim/MoneyPilot_app/releases)
2. Enable "Install from Unknown Sources" in Settings → Security
3. Open the APK and install

#### Option 2: Build from Source
```bash
# Clone the repository
git clone https://github.com/Iftekhar-Tasnim/MoneyPilot_app.git
cd MoneyPilot_app

# Install dependencies
flutter pub get

# Run the app
flutter run

# Or build APK
flutter build apk --release
```

### Configuration
1. Open the app and tap **Settings** (⚙️ icon)
2. Tap **Configure Gemini API**
3. Paste your API Key and tap **Save Key**
4. (Optional) Tap **Test API** to verify connection

---

## 🛠️ Tech Stack
- **Framework**: Flutter 3.x
- **AI Model**: Google Gemini (via `google_generative_ai`)
- **Database**: `sqflite` (SQLite)
- **Voice**: `speech_to_text`
- **Notifications**: `flutter_local_notifications`
- **Charts**: `fl_chart`
- **Fonts**: `google_fonts`
- **State Management**: `setState` (Clean & Simple)

## 📱 Features Breakdown

| Feature | Status | Description |
|---------|--------|-------------|
| Voice Input | ✅ | Speak to add transactions |
| Manual Entry | ✅ | Quick action buttons |
| Income Tracking | ✅ | Salary, bonuses, other income |
| Expense Tracking | ✅ | Auto-categorized expenses |
| Loan Management | ✅ | Track given/taken loans |
| AI Insights | ✅ | Financial coaching & tips |
| Notifications | ✅ | In-app center + scheduled alerts |
| Spending Trends | ✅ | Charts with filters |
| Multi-Language | ✅ | English & Bangla |
| Learning Loop | ✅ | Remembers user corrections |
| Preprocessing | ✅ | Handles Bangla numbers & clauses |

## 📸 Screenshots
> Add screenshots showcasing the dashboard, voice input, AI insights, and notification center

## 🤝 Contributing
Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests

## 📄 License
This project is open source and available under the MIT License.

## 👨‍💻 Developer
**Iftekhar Tasnim**  
[GitHub](https://github.com/Iftekhar-Tasnim) | [Repository](https://github.com/Iftekhar-Tasnim/MoneyPilot_app)

---

**Made with ❤️ using Flutter & Gemini AI**

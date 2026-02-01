# Money Pilot - Smart AI Expense Tracker

**Money Pilot** is a modern, voice-powered personal finance tracker built with **Flutter** and **Google Gemini AI**.  
It allows you to track your daily income and expenses by simply speaking naturally in **English** or **Bangla**.

## ✨ Key Features

  > [!TIP]
  > Just tap the microphone and say: *"I spent 500 taka on groceries"* or *"Got salary 50,000"*.

### 🎙️ AI Voice Interaction
-   **Natural Language Processing**: Uses `SpeechToText` + **Google Gemini AI** to understand your speech.
-   **Smart Categorization**: Automatically detects if it's an **Income** or **Expense**, extracts the **Amount**, and assigns a **Category** (e.g., Food, Transport, Salary).
-   **Multi-Language Support**: Works in **English** and **Bangla** (`bn_BD`).
-   **Robust Error Handling**: Auto-detects silence, timeouts, and API errors with helpful feedback.

### 🧠 Advanced AI Integration
-   **Smart Model Discovery**: Automatically tests and finds the best available Gemini model (`1.5-flash`, `pro`, etc.) compatible with your specific API Key.
-   **Test & Validation**: Built-in "Test API" feature in Settings to verify your connection instantly.

### 📱 Modern UI/UX
-   **Dashboard**: Real-time Total Balance, Income, and Expense summary.
-   **Transaction List**: Clean, timeline-based history of your spending.
-   **Dual Input**: Add transactions via **Voice** (FAB) or **Manual Entry** (Quick Action buttons).
-   **Localization**: Instant English/Bangla language switching.

### 🔒 Data Privacy & Storage
-   **Offline-First**: All transaction data is stored locally on your device using **SQLite**.
-   **Secure Keys**: Your API Key is stored locally in `SharedPreferences` and never shared.

---

## 🚀 Getting Started

### Prerequisites
-   A **Google Gemini API Key** (Get one [here](https://aistudio.google.com/app/apikey)).
-   Internet connection (for AI processing).
-   Microphone permission enabled.

### Installation
1.  **Clone the repo**:
    ```bash
    git clone https://github.com/yourusername/money_pilot.git
    cd money_pilot
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the app**:
    ```bash
    flutter run
    ```

### Configuration
1.  Open the app and go to **Settings** (Gear icon).
2.  Tap **Configure Gemini API**.
3.  Paste your API Key and tap **Save Key**.
4.  (Optional) Tap **Test API** to verify it works.

---

## 🛠️ Tech Stack
-   **Framework**: Flutter 3.x
-   **AI Model**: Google Gemini (via `google_generative_ai`)
-   **Database**: `sqflite`
-   **Voice**: `speech_to_text`
-   **State Management**: `setState` (Clean & Simple)

## 🔮 Future Roadmap
-   [ ] Monthly/Weekly Charts & Analytics.
-   [ ] Budget limits and alerts.
-   [ ] Data Backup/Export (CSV/JSON).

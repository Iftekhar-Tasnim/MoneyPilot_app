# Money Pilot - Detailed Project Plan (Updated)

## 1. Input & Interaction
*   [x] **Voice-First Interface**: Prominent microphone button for recording.
*   [x] **Automatic Language Detection**: Supports English and Bengali voice commands.
*   [x] **Natural Language Processing (NLP)**: `GeminiService` to parse transactions.

## 2. Core Financial Tracking
*   [x] **Expense Categorization**: Auto-sorting into standard categories.
*   [x] **Manual Override**: Edit/Delete transactions.
*   [x] **Dual Loan Tracking**:
    *   [x] **Given Loans**: Track money lent to others (Asset).
    *   [x] **Taken Loans**: Track money borrowed (Liability).
*   [x] **Income Management**: Input monthly salary to track "Remaining Balance".

## 3. Data Management & Privacy
*   [x] **Local-First Storage**: SQLite database (`sqflite`) keeps all data on-device.
*   [x] **Monthly Cycle Logic**:
    *   [x] **Automatic Reset**: Dashboard focuses on current month.
    *   [x] **Historical Archive**: Access previous months' data via "All Transactions".

## 4. AI Insights & Analysis
*   [x] **Financial Health Dashboard**:
    *   [x] **Total Expense**: Visible on Dashboard.
    *   [x] **Income vs Expense**: Balance Card visualisation.
    *   [x] **Net Position**: (Income - Expenses + Loans).
*   [x] **Performance Summary**: "What is going well" (AI Feedback).
*   [x] **Actionable Suggestions**: "What to do better" (AI Advice).

## 5. Technical Requirements
*   [x] **Mobile-Responsive**: Flutter UI adapts to screen sizes.
*   [x] **Offline Capability**: Core features work offline; AI requires internet.
*   [ ] **Light/Dark Mode**: System-aware theming (Partially implemented, needs verification).

---

## ✅ Completed Milestones
*   **Foundation**: Project structure, MVVM architecture, App Icon/Logo.
*   **Voice & AI**: Speech-to-Text integration, Gemini API parsing, Smart Model Discovery.
*   **UI/UX**: Dashboard with Charts (Line), Localization (En/Bn), Privacy Policy, Settings.
*   **Features**: Income Management, Loan Tracking, Quick Stats, AI Money Coach.

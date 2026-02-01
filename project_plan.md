# Smart Voice Expense Tracker - Project Progress

## ✅ Completed Milestones

### Phase 1: Foundation & UI
-   [x] **Project Structure**: Set up clean MVVM-style folder structure.
-   [x] **Dashboard UI**: Implemented Balance Card, Transaction List, and Language Switcher.
-   [x] **Manual Input**: Added Income/Expense forms with category selection.
-   [x] **Localization**: Full English and Bangla UI translation.

### Phase 2: Core Services (The Brains)
-   [x] **Database Integration**: Set up SQLite (`DatabaseService`) for persistent local storage.
-   [x] **Voice Service**: specialized `VoiceService` with timeout handling and error recovery.
-   [x] **Gemini AI Service**: 
    -   Implemented `GeminiService` to parse natural language.
    -   Added **Smart Model Discovery** to auto-detect valid models (`flash`, `pro`) for the user's key.
    -   Engineered prompts for accurate JSON extraction context-aware categorization.

### Phase 3: Settings & Configuration
-   [x] **API Key Management**: storage securement via `SharedPreferences`.
-   [x] **Test API Feature**: Added a diagnostic tool to verify API connection and model compatibility.
-   [x] **Dynamic Error Handling**: detailed feedback for network or API issues.

---

## 🚧 In Progress / Next Steps

### Phase 4: Data Visualization (Coming Soon)
-   [ ] **Charts**: Add Pie/Bar charts to visualize spending by category.
-   [ ] **Time Filters**: View expenses by Week, Month, or Custom Date.

### Phase 5: Advanced Features
-   [ ] **Budget Goals**: Set monthly limits for categories (e.g., "Food: 5000 tk").
-   [ ] **Backup & Restore**: Export data to JSON/CSV for safety.
-   [ ] **Receipt Scanning**: Use Gemini Vision to scan paper receipts? (Potential feature!)

## 🐛 Known Issues & Notes
-   **Bangla Voice Input**: Works well but requires the Android/iOS device to have the Bangla language pack installed in system settings.
-   **API Limits**: Free Gemini keys have rate limits; app handles basic errors but heavy usage might require backoff logic.

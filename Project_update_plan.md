# MoneyPilot App – Structured Upgrade Plan (AI‑Friendly)

This document is a **step‑by‑step execution plan** to upgrade the MoneyPilot app from a *model‑driven prototype* into a **controlled, production‑grade voice finance app**.

This plan is written to be **AI‑agent friendly** (Antigravity / Cursor / Copilot) and can be followed incrementally without breaking the app.

---

## 🎯 Goal (Do Not Skip)

Convert free‑form **Bangla + English voice input** into **accurate, structured financial transactions** with:

* High reliability
* User trust
* Offline‑first SQLite storage
* Low hallucination risk

---

## 🧠 Core Design Principle

> **AI must be boxed.**
> The app owns the logic. The AI only extracts structured data.

AI is **not** allowed to:

* Decide business logic
* Invent categories
* Save data directly
* Skip user confirmation

---

## 🏗 Target Architecture (Final)

```
Voice Input
 ↓
Speech‑to‑Text
 ↓
Pre‑Processing (rules, cleanup)
 ↓
Rule Overrides (known phrases)
 ↓
LLM (STRICT JSON extraction only)
 ↓
Validation Layer
 ↓
User Confirmation UI
 ↓
SQLite (ledger)
```

---

## PHASE 1 — Stabilize AI Output (CRITICAL)

### Objective

Make AI output **predictable, parseable, and safe**.

### Tasks

1. **Rewrite Gemini prompt** to:

   * Return ONLY valid JSON
   * No explanation text
   * Fixed schema

2. **Disable auto‑save** from AI response

3. **Reject malformed JSON** before UI

### Output Contract (STRICT)

```json
{
  "transactions": [
    {
      "type": "expense | income",
      "amount": 0,
      "category": "Food | Transport | Shopping | Bills | Income | Other",
      "note": "string"
    }
  ]
}
```

### AI Instruction (for Antigravity)

> Do not allow the model to generate text outside JSON. If JSON parsing fails, retry once, then abort.

---

## PHASE 2 — Pre‑Processing Layer (Before AI)

### Objective

Improve accuracy **before** AI is called.

### Add a new module

```
lib/services/preprocessing/
```

### Responsibilities

1. Normalize Bangla numbers → English numerics
2. Remove filler words (আজকে, মানে, তো)
3. Split multiple transactions

### Example

Input:

```
আজকে বাজারে পাঁচশ টাকা আর বাসে পঞ্চাশ টাকা
```

Output:

```
["বাজারে 500 টাকা", "বাসে 50 টাকা"]
```

### AI Instruction

> Always process **each clause separately**. Never send multi‑transaction text to the model.

---

## PHASE 3 — Rule‑Based Overrides (Before Save)

### Objective

Prevent obvious AI mistakes.

### Create

```
lib/services/rules/category_rules.dart
```

### Example Map

```dart
{
  "বাস": "Transport",
  "রিকশা": "Transport",
  "চা": "Food",
  "বাজার": "Shopping",
  "ফ্রিল্যান্স": "Income"
}
```

### Logic

* If keyword exists → override AI category
* AI becomes fallback, not authority

### AI Instruction

> Apply deterministic rules before trusting model output.

---

## PHASE 4 — Validation Layer (Hard Guardrails)

### Objective

Protect financial integrity.

### Validation Rules

* amount > 0
* amount < configured upper limit
* category ∈ allowed list
* type ∈ {income, expense}

### Behavior

* If invalid → block save
* Show correction UI

### AI Instruction

> Never insert into SQLite without validation pass.

---

## PHASE 5 — Mandatory Confirmation UI

### Objective

Build **user trust**.

### UI Flow

```
Detected Transactions
 • Category — Amount

[Confirm]   [Edit]
```

### Rules

* No silent save
* User can edit category or amount
* Confirm required for DB insert

### AI Instruction

> Assume AI output is a draft, not truth.

---

## PHASE 6 — SQLite Learning Loop (Personalization)

### Objective

Improve accuracy over time **without more AI calls**.

### Add Table

```sql
CREATE TABLE correction_memory (
  phrase TEXT PRIMARY KEY,
  correct_category TEXT
);
```

### Flow

1. User edits category
2. Save phrase → category
3. Apply mapping before AI next time

### AI Instruction

> Check correction memory before invoking model.

---

## PHASE 7 — Code Structure Refactor (Minimal but Clean)

### Target Structure

```
lib/
 ├─ ui/
 ├─ services/
 │   ├─ speech/
 │   ├─ preprocessing/
 │   ├─ ai/
 │   ├─ rules/
 │   └─ database/
 ├─ models/
 └─ utils/
```

### Rule

* UI contains NO business logic
* Services are testable

---

## PHASE 8 — Testing (Low Effort, High Value)

### Add Unit Tests For

* Number normalization
* Rule overrides
* AI JSON parsing
* SQLite insert validation

### AI Instruction

> Write tests for logic, not UI.

---

## 🚀 Final Outcome

After this plan:

* Gemini accuracy feels **90%+**
* Users trust the app
* Offline works reliably
* App is extensible (sync, cloud, analytics)

---

## 🧭 Execution Order (Strict)

1. Phase 1
2. Phase 2
3. Phase 3
4. Phase 5
5. Phase 4
6. Phase 6
7. Phase 7
8. Phase 8

---

## Final Instruction for AI Tools

> Follow phases sequentially. Do not optimize early. Do not remove guardrails. Treat AI output as untrusted input.

---

**This plan is intentionally strict.**
Strict systems scale. Loose systems fail silently.

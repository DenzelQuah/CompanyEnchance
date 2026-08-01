🌏 ASEAN Nexus
*Your AI-Powered MSME Growth Engine*

**Project Links**
- Google Drive(include report and demo video): https://drive.google.com/drive/folders/1Fhy_onQH1SY0pHod9JGOxqOlTLaSYrH4?usp=sharing
- Figma: https://www.figma.com/design/77wCwxKarVVNumYtTDtW3R/CS8?node-id=0-1&t=qbcLPExCvQ4gIbVV-1

> **Achievements:** 🥇 Gold Medalist — CITREX 2026 | Participant — BorNEO HackWknd 2026
> **CITREX 2026 Gold Medal Announcement:** [View LinkedIn Post](https://www.linkedin.com/feed/update/urn:li:activity:7464540353996595202/)

Built by Team Journey2DeWest - Theme: AI for Inclusive MSME Growth
Members: 
1) Allan Tan (allantan0930@gmail.com)
2) Denzel Quah (denzelquahkahliang@gmail.com)
3) Low Jia Cheng (jclow2005@gmail.com)
4) Chan Xin Kai (chanxinkai8861@gmail.com)

---

## 📌 General Description

*What Project does:*

ASEAN Nexus is an AI-driven consultative platform designed to support the growth of Micro, Small, and Medium Enterprises (MSMEs). It provides diagnostic business surveys, AI-generated growth roadmaps, financial tracking tools, and an integrated Retrieval-Augmented Generation (RAG) assistant to guide entrepreneurs through practical business decisions. It simplifies access to business intelligence and digital tools, helping informal micro-businesses transition into structured, competitive, and revenue-generating enterprises. 

*SDG Addressed:*
* *SDG 8: Decent Work and Economic Growth:* The app empowers MSMEs by providing personalized growth roadmaps, step-by-step guidance, and built-in financial tracking to monitor revenue and expenses, promoting entrepreneurial empowerment and sustainable business growth. It also connects users with relevant government and private loan opportunities.
* *SDG 9: Industry, Innovation, and Infrastructure:* The platform acts as a digital bridge, promoting technological upgrading by recommending specific modern software tools and providing a centralized infrastructure for business management. The RAG AI bot serves as an advanced technological infrastructure, democratizing access to high-level business intelligence and fostering a culture of innovation.

*Target Users:*
1) ASEAN MSMEs.

---

## ⚠️ The Problem

MSMEs form the economic foundation of ASEAN, but face critical structural barriers:
1.  *Fragmented and Generic Business Guidance:* Existing resources offer high-level information without actionable, step-by-step execution plans tailored to specific industries.
2.  *Challenge Faces of Capital Access:* Navigating funding landscapes is difficult, and MSMEs often lack the structured financial data needed to secure growth capital.
3.  *Lack of Digital Integration:* Traditional MSMEs often rely on manual, disconnected processes and lack the technical knowledge to implement modern digital tools.
4.  *Real-Time Contextual Help Support Issue:* Micro-businesses cannot afford consultants and lack localized troubleshooting when facing roadblocks.
5.  *Poor Visibility in Financial Tracking and Goal Motivation:* A lack of tools to track revenue against growth goals hinders long-term sustainability and financial discipline.

---

## 🚀 Key Features

* *Intelligent Profiling (Business Survey):* Captures the user's sector, budget, maturity, and primary goals to calculate readiness scores.
* *Dynamic AI Growth Roadmaps:* Translates generic advice into actionable, gamified micro-tasks (with XP and level tracking).
* *Contextual Tool Recommendations:* Curates and suggests modern digital tools at the exact moment the MSME needs them (e.g., prompting MATRADE registration for export readiness).
* *Nexus AI Coach (RAG-Powered):* An integrated AI chatbot that understands the user's current roadmap step and business profile to provide highly localized, context-aware troubleshooting.
* *Funding & Resource Explorer:* Automatically matches users with relevant grants and financial resources based on their current growth milestone.

---

## 💻 Tech Stack

ASEAN Nexus is built on a modernized architecture:

* *Frontend:* [Flutter](https://flutter.dev/) (Cross-platform mobile application).
* *Local Storage:* SQLite (For offline data caching and state persistence).
* *Backend & Auth:* [Supabase](https://supabase.com/) (Handles secure user authentication, structured progress data, and acts as a Vector Database for matching relevant business grants).
* *AI Engine:* Google Gemini AI (Serves as the core intelligence layer, performing semantic searches against Supabase vector embeddings to return localized advice, predictive projections, and actionable roadmap steps).

---

## ⚙️ How It Works (System Flow)

1. *Onboarding & Profiling:* The user completes a business profile survey (captured by the SurveyModel) which informs their "Readiness Scores"
2. *Roadmap Generation:* Supabase and Gemini AI process the profile to generate a JSON array, populating the MilestoneModel with actionable steps, grants, and resources.
3. *Execution & Tracking:* As the user completes micro-tasks, progress feeds into the Dashboard Summary, updating growth metrics and visual indicators (like the Radar Score).
4. *Contextual Support:* When a user asks the "Nexus Coach" for help, the app injects their current user context and current step into the ChatState & ChatMessage model.
5. *AI Query & Response:* This combined payload is sent to the backend, where Gemini AI processes the context and returns tailored advice.

---

## 🔮 Future Scope

Through phased development, we plan to implement the following features:

* *Enhance RAG Knowledge Base:* Continuously expand the Retrieval-Augmented Generation (RAG) database with localized, industry-specific data for more precise business intelligence.
* *Refine AI Prompt Engineering:* Optimize system prompts to improve the nuance, relevance, and accuracy of the AI Business Coach's responses, and improve the speed of roadmap generation.
* *Optimize UI/UX for Resource Portals:* Redesign the interface for analyzing resource options (grants, loans, etc.) to ensure a smoother, more intuitive user journey.
* *Implement Advanced Financial Tools:* * *Predictive Revenue Analytics:* Introduce tools that analyze historical data to forecast future sales trends.
* *AI-Based Financial Forecasting:* Integrate intelligent modelling to help MSMEs anticipate cash flow needs and optimize budget allocation.
* *Develop a Mentor Matchmaking Feature:* Create a system to connect MSME owners with experienced industry mentors for personalized, human-in-the-loop guidance.
---

# Setup Instructions
## Prerequisites
- Flutter SDK installed
- Python 3.12+ installed
- Gemini AI API key (GEMINI_API_KEY)
- Supabase project and database initialized

**Procedure to create API keys for LLM model**
1) Go to `https://aistudio.google.com/app/api-keys`
2) Click `Create API key`
3) Copy the generated API key
4) Paste it into `GEMINI_API_KEY` in both `.env` and `backend/.env`

**Supabase setup and SQL**
1) Create a Supabase project at `https://app.supabase.com`
2) Open the SQL Editor in your Supabase project
3) Copy the contents of `sqlquery.txt` and run it in the SQL Editor
4) Keep the project URL and service role key for `backend/.env`

**1) Backend (FastAPI)**
```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
```
Edit `backend/.env` and set:
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `GEMINI_API_KEY`

Run the backend:
```powershell
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```
Health check:
```powershell
Invoke-WebRequest http://localhost:8000/health -UseBasicParsing
```

**1.1) Business Knowledge Base for RAG**

A business knowledge markdown file is located in `backend/` (example: `backend/asean_nexus_knowledge_base.md`). Without this, RAG chatbot cannot function as expected.

Ingest it into the business knowledge vector table:
```powershell
# Option A (from inside `backend/`):
python scripts/insert_markdown_roadmap_knowledge.py --file "C:\path\to\backend\asean_nexus_knowledge_base.md" --source-doc-id "business:asean-nexus-kb-v1"

# Option B (from repo root):
python backend/scripts/insert_markdown_roadmap_knowledge.py --file "C:\path\to\backend\asean_nexus_knowledge_base.md" --source-doc-id "business:asean-nexus-kb-v1"

# Option C (from repo root via wrapper):
python scripts/insert_markdown_roadmap_knowledge.py --file "C:\path\to\backend\asean_nexus_knowledge_base.md" --source-doc-id "business:asean-nexus-kb-v1"
```

**2) Frontend (Flutter)**
Edit root `.env` and set `CHAT_API_URL`:
- Android emulator: `http://10.0.2.2:8000/chat`
- iOS simulator / Windows desktop: `http://localhost:8000/chat`
- Physical phone: `http://<YOUR_PC_LAN_IP>:8000/chat`

Then run:
```powershell
flutter pub get
flutter run
```

**How To Interact With The Prototype**
**Step-by-step guide for judges**
1) Launch the app and register a new account (or sign in).
2) Complete the diagnostic survey (10 steps). Use realistic business inputs.
3) After completion, you should land on the main dashboard.
4) Open the Roadmap tab to view AI-generated milestones and progress.
5) Open the Financial tab to view readiness and grant recommendations.
6) Open the Chat/AI assistant to ask roadmap questions.
7) Open the Forum tab to share thoughts and ideas.

**Suggested test case**
Use this consistent dataset to validate behavior:
- Business Name: "Nusantara Snacks"
- Sector: Food & Beverage
- Location: Kuala Lumpur, Malaysia
- Sales Tracking: Excel
- Team Size: 8
- Primary Goal: Export to ASEAN
- Audited Statements: No
- Digital Presence: Facebook, Shopee, WhatsApp
- Supply Chain: Mixed
- Weekly Commitment: 10-20 hours
- Budget Plan: Investment-Ready

**Expected result**
- Dashboard shows a readiness score > 40
- Roadmap includes export-focused milestones
- Financial screen shows improvement areas and potential support programs

**Achievement**
- CITREX 2026 (Gold Medalist)
- BorNEO HackWknd 2026 (Participant award)
- Dubai Future Solutions 2026 


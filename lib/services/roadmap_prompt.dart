import '../model/survey_model.dart';

class RoadmapPromptBuilder {

  // ─── ASEAN country resource catalogue ────────────────────────────────────
  // Injected directly into the prompt so the AI can pick the right 2–3 entries
  // for the user's country and milestone topic.

  static String _buildCountryResourceCatalogue(String location) {
    final loc = location.toLowerCase();

    if (loc.contains('malaysia')) {
      return '''
MALAYSIA RESOURCE CATALOGUE (pick the 2–3 most relevant per milestone):
- { "name": "SME Digitalization Grant", "type": "Grant", "provider": "SME Corp / MDEC", "eligibility": "Malaysian SME, 60%+ local equity", "maxAmount": "RM 5,000", "processingTime": "4–6 weeks", "highlight": "Covers approved digital tool subscriptions", "url": "https://www.smebank.com.my/en/products-services/sme-digitalization-grant" }
- { "name": "Business Accelerator Programme (BAP)", "type": "Grant", "provider": "SME Corp Malaysia", "eligibility": "SMEs with min 2 years operation", "maxAmount": "Up to RM 300,000", "processingTime": "8–12 weeks", "highlight": "Full business development and market expansion support", "url": "https://www.smecorp.gov.my/index.php/en/programmes/2015-12-21-08-39-38/business-accelerator-programme" }
- { "name": "MATRADE Market Development Grant (MDG)", "type": "Grant", "provider": "MATRADE", "eligibility": "Registered Malaysian exporters", "maxAmount": "Up to RM 300,000 cumulative", "processingTime": "6–8 weeks", "highlight": "Reimburses export promotion costs including fairs and e-commerce setup", "url": "https://www.matrade.gov.my/en/malaysian-exporters/services-for-exporters/develop-your-export-market/mdg" }
- { "name": "BNM PENJANA Micro Loan", "type": "Loan", "provider": "Bank Negara Malaysia", "eligibility": "Micro-enterprises, max 5 employees", "maxAmount": "RM 75,000", "processingTime": "2–3 weeks", "highlight": "Low-interest financing with flexible repayment terms", "url": "https://www.bnm.gov.my" }
- { "name": "MDEC eTRADE Programme", "type": "Grant", "provider": "MDEC", "eligibility": "Malaysian SMEs in e-commerce", "maxAmount": "RM 5,000 per year", "processingTime": "3–4 weeks", "highlight": "Subsidised onboarding fees for approved e-marketplaces", "url": "https://mdec.my/etrade" }
- { "name": "SME Bank Biz Mula-Mula Loan", "type": "Loan", "provider": "SME Bank Malaysia", "eligibility": "Start-ups less than 4 years old", "maxAmount": "RM 500,000", "processingTime": "4–6 weeks", "highlight": "Startup-friendly financing with no collateral requirement", "url": "https://www.smebank.com.my" }
''';
    }

    if (loc.contains('singapore')) {
      return '''
SINGAPORE RESOURCE CATALOGUE (pick the 2–3 most relevant per milestone):
- { "name": "Enterprise Development Grant (EDG)", "type": "Grant", "provider": "Enterprise Singapore", "eligibility": "Singapore-registered SME, 30%+ local equity", "maxAmount": "Up to 50% of qualifying costs", "processingTime": "6–8 weeks", "highlight": "Covers capability development, innovation and internationalisation", "url": "https://www.enterprisesg.gov.sg/financial-support/enterprise-development-grant" }
- { "name": "Productivity Solutions Grant (PSG)", "type": "Grant", "provider": "Enterprise Singapore / IMDA", "eligibility": "Singapore-registered SMEs in approved sectors", "maxAmount": "Up to 50% of solution cost", "processingTime": "4–6 weeks", "highlight": "Pre-approved list of digital and automation solutions", "url": "https://www.enterprisesg.gov.sg/financial-support/productivity-solutions-grant" }
- { "name": "SkillsFuture Enterprise Credit (SFEC)", "type": "Credit", "provider": "SkillsFuture Singapore", "eligibility": "Eligible employers with 3+ Singapore employees", "maxAmount": "SGD 10,000 credit", "processingTime": "2–4 weeks", "highlight": "Offsets cost of workforce transformation and upskilling programmes", "url": "https://www.skillsfuture.gov.sg/sfec" }
- { "name": "Market Readiness Assistance (MRA)", "type": "Grant", "provider": "Enterprise Singapore", "eligibility": "Singapore SMEs entering new overseas markets", "maxAmount": "Up to 50% of eligible costs, capped at SGD 100,000", "processingTime": "6–8 weeks", "highlight": "Supports overseas market setup and business development", "url": "https://www.enterprisesg.gov.sg/financial-support/market-readiness-assistance-grant" }
- { "name": "Startup SG Founder Grant", "type": "Grant", "provider": "Enterprise Singapore", "eligibility": "First-time entrepreneurs with innovative concept", "maxAmount": "SGD 50,000", "processingTime": "8–12 weeks", "highlight": "Mentorship plus capital injection for early-stage startups", "url": "https://www.startupsg.gov.sg/programmes/4894/startup-sg-founder" }
''';
    }

    if (loc.contains('indonesia')) {
      return '''
INDONESIA RESOURCE CATALOGUE (pick the 2–3 most relevant per milestone):
- { "name": "KUR (Kredit Usaha Rakyat)", "type": "Loan", "provider": "Ministry of Finance / State Banks", "eligibility": "Indonesian MSMEs with valid business identity", "maxAmount": "IDR 500 million (micro tier)", "processingTime": "1–2 weeks", "highlight": "Subsidised interest rate at 6% per annum for small businesses", "url": "https://kur.ekon.go.id" }
- { "name": "LPEI Export Financing", "type": "Loan", "provider": "Indonesia Eximbank (LPEI)", "eligibility": "Indonesian exporters all sectors", "maxAmount": "IDR 10 billion and above", "processingTime": "4–8 weeks", "highlight": "Export buyer credit and working capital for exporters", "url": "https://www.lpei.go.id/en" }
- { "name": "PLUT-KUMKM Business Development", "type": "Free Service", "provider": "Ministry of Cooperatives and SMEs", "eligibility": "All Indonesian SMEs", "maxAmount": "Free services", "processingTime": "Immediate walk-in", "highlight": "Free business consulting, training and mentoring centres nationwide", "url": "https://www.depkop.go.id" }
- { "name": "Bangga Buatan Indonesia (BBI) Digital Onboarding", "type": "Programme", "provider": "Coordinating Ministry for Economic Affairs", "eligibility": "Indonesian MSMEs going digital", "maxAmount": "Subsidised or free", "processingTime": "1–2 weeks", "highlight": "Fast-track onboarding to Tokopedia, Shopee and Bukalapak", "url": "https://bangga-buatan-indonesia.id" }
- { "name": "PNM Mekaar Micro Financing", "type": "Loan", "provider": "Permodalan Nasional Madani (PNM)", "eligibility": "Women micro-entrepreneurs in Indonesia", "maxAmount": "IDR 10 million initial", "processingTime": "1 week", "highlight": "Group lending model with no collateral and weekly repayment", "url": "https://www.pnm.co.id/mekaar" }
''';
    }

    if (loc.contains('thailand')) {
      return '''
THAILAND RESOURCE CATALOGUE (pick the 2–3 most relevant per milestone):
- { "name": "SME Development Bank Soft Loan", "type": "Loan", "provider": "SME Development Bank of Thailand", "eligibility": "Thai-registered SMEs max THB 500M annual revenue", "maxAmount": "THB 15 million", "processingTime": "3–4 weeks", "highlight": "Below-market interest rates with flexible collateral options", "url": "https://www.smebank.co.th/en" }
- { "name": "BOI Smart SME Program", "type": "Incentive", "provider": "Board of Investment Thailand", "eligibility": "Thai SMEs in BOI target industries", "maxAmount": "Varies by project size", "processingTime": "8–12 weeks", "highlight": "Tax incentives and investment promotion for priority growth sectors", "url": "https://www.boi.go.th" }
- { "name": "DITP Export Promotion Grant", "type": "Grant", "provider": "Department of International Trade Promotion", "eligibility": "Thai exporters and SMEs", "maxAmount": "THB 200,000", "processingTime": "4–6 weeks", "highlight": "Covers trade fair participation and international market development", "url": "https://www.ditp.go.th" }
- { "name": "TCG Credit Guarantee", "type": "Guarantee", "provider": "Thai Credit Guarantee Corporation (TCG)", "eligibility": "Thai SMEs lacking sufficient collateral", "maxAmount": "Up to 40 million THB guarantee", "processingTime": "2–4 weeks", "highlight": "Allows SMEs without full collateral to access bank loans", "url": "https://www.tcg.or.th" }
''';
    }

    if (loc.contains('vietnam')) {
      return '''
VIETNAM RESOURCE CATALOGUE (pick the 2–3 most relevant per milestone):
- { "name": "SME Support Fund Credit Guarantee", "type": "Guarantee", "provider": "Vietnam Development Bank", "eligibility": "Vietnamese-registered SMEs", "maxAmount": "VND 5 billion", "processingTime": "3–5 weeks", "highlight": "Credit guarantee to help SMEs access commercial bank loans", "url": "https://www.vdb.gov.vn" }
- { "name": "National SME Development Program", "type": "Free Service", "provider": "Ministry of Planning and Investment", "eligibility": "All Vietnamese SMEs", "maxAmount": "Free training and consultation", "processingTime": "Immediate", "highlight": "Free business registration, legal consultation and market access support", "url": "https://business.gov.vn" }
- { "name": "VCCI Business Support Services", "type": "Service", "provider": "Vietnam Chamber of Commerce and Industry", "eligibility": "All Vietnamese businesses", "maxAmount": "Subsidised services", "processingTime": "1–2 weeks", "highlight": "Trade promotion, legal advisory and international market connections", "url": "https://www.vcci.com.vn" }
- { "name": "Vinasa Digital Transformation Fund", "type": "Grant", "provider": "Vietnam Software and IT Services Association", "eligibility": "Vietnamese SMEs in digital transformation", "maxAmount": "VND 500 million", "processingTime": "6–8 weeks", "highlight": "Supports SME digitisation with IT consulting and tool subsidies", "url": "https://vinasa.org.vn" }
''';
    }

    if (loc.contains('philippines')) {
      return '''
PHILIPPINES RESOURCE CATALOGUE (pick the 2–3 most relevant per milestone):
- { "name": "MSME Credit Guarantee Program", "type": "Guarantee", "provider": "Philippine Guarantee Corporation (PhilGuarantee)", "eligibility": "Filipino MSMEs with bank accounts", "maxAmount": "PHP 5 million", "processingTime": "2–4 weeks", "highlight": "Guarantee covers 70 to 80 percent of bank loan for easier approval", "url": "https://www.philguarantee.gov.ph" }
- { "name": "DTI Negosyo Center Services", "type": "Free Service", "provider": "Department of Trade and Industry", "eligibility": "All Filipino SMEs", "maxAmount": "Free services", "processingTime": "Walk-in same day", "highlight": "One-stop shop for business registration, coaching and tech assistance", "url": "https://www.dti.gov.ph/negosyo/" }
- { "name": "SB Corp CARES Loan Program", "type": "Loan", "provider": "Small Business Corporation Philippines", "eligibility": "Filipino SMEs affected by economic disruption", "maxAmount": "PHP 5 million", "processingTime": "2–3 weeks", "highlight": "Low-interest loans at 0.5% monthly with grace period option", "url": "https://www.sbcorp.gov.ph" }
- { "name": "DOST Technology Business Incubation", "type": "Programme", "provider": "Department of Science and Technology", "eligibility": "Tech-enabled Filipino startups and SMEs", "maxAmount": "Up to PHP 5 million in kind support", "processingTime": "4–8 weeks", "highlight": "R&D support, lab access, IP assistance and commercialisation guidance", "url": "https://www.dost.gov.ph" }
''';
    }

    // Generic ASEAN fallback
    return '''
ASEAN GENERAL RESOURCE CATALOGUE (pick 2–3 most relevant, note the region):
- { "name": "ASEAN SME Service Centre", "type": "Free Service", "provider": "ASEAN Secretariat", "eligibility": "All ASEAN-registered SMEs", "maxAmount": "Free advisory", "processingTime": "1–2 weeks", "highlight": "Regional market access advisory and cross-border trade support", "url": "https://www.asean.org/asean-economic-community/sectoral-bodies-under-the-purview-of-aem/small-and-medium-enterprises/" }
- { "name": "ADB SME Finance Program", "type": "Loan / Guarantee", "provider": "Asian Development Bank", "eligibility": "SMEs in ADB member countries", "maxAmount": "Varies by country partner bank", "processingTime": "4–8 weeks", "highlight": "Trade finance guarantees and working capital for cross-border ASEAN trade", "url": "https://www.adb.org/what-we-do/topics/sme-finance" }
- { "name": "IFC SME Ventures Fund", "type": "Investment", "provider": "International Finance Corporation (World Bank Group)", "eligibility": "Growth-stage SMEs in developing markets", "maxAmount": "USD 1–5 million equity", "processingTime": "12–20 weeks", "highlight": "Equity and quasi-equity investment for high-growth SMEs", "url": "https://www.ifc.org/en/what-we-do/sectors/financial-institutions/sme-finance" }
''';
  }

  // ─── Main narrative prompt ────────────────────────────────────────────────

  static String buildSystemPrompt(SurveyModel survey) {
    final digitalScore = _calculateDigitalScore(survey);
    final opsScore = _calculateOpsScore(survey);
    final exportScore = _calculateExportScore(survey, opsScore, digitalScore);
    final scaleScore = _calculateScaleScore(survey, opsScore);

    final digitalString = survey.digitalPresence.isEmpty
        ? 'None'
        : survey.digitalPresence.join(', ');

    final constraints = _buildConstraints(survey, digitalScore);
    final goalSection = _buildGoalSection(survey);

    return '''
You are a senior MSME Growth Strategist specializing in Southeast Asian markets.
You have deep knowledge of SME Corp Malaysia, MATRADE, MDEC, BNM financing schemes,
and ASEAN SME Policy Index research.

═══════════════════════════════════════
BUSINESS PROFILE (from diagnostic survey)
═══════════════════════════════════════
Business Name   : ${survey.businessName}
Sector          : ${survey.sector}
Location        : ${survey.location}
Team Size       : ${survey.teamSize} people
Primary Goal    : ${survey.primaryGoal?.label ?? 'General Growth'}
Sales Tracking  : ${survey.salesTracking?.label ?? 'Unknown'}
Audited Accounts: ${survey.hasAuditedStatements ? 'Yes' : 'No'}
Digital Platforms: $digitalString
Supply Chain    : ${survey.supplyChain?.label ?? 'Unknown'}
Weekly Time     : ${survey.weeklyCommitment?.label ?? 'Unknown'}
Budget Type     : ${survey.budgetPlan?.label ?? 'Unknown'}

Diagnostic Scores (calculated from answers above):
  Digital Maturity     : $digitalScore/10
  Operational Maturity : $opsScore/10
  Export Readiness     : $exportScore/10
  Scalability Readiness: $scaleScore/10

═══════════════════════════════════════
HARD CONSTRAINTS — ENFORCE THESE FIRST
═══════════════════════════════════════
$constraints

═══════════════════════════════════════
CORE INSTRUCTIONS
═══════════════════════════════════════
Every recommendation MUST:
1. Reference the specific survey answer that triggered it.
   Format: "Because you selected [answer], you currently face [problem]. Here is how to fix it:"
2. Include numbered micro-steps (as many as genuinely needed — minimum 4, no upper limit).
   Each step must be specific, actionable and executable by a ${survey.teamSize}-person team.
3. Name the exact tool or platform to use (not just "use social media").
4. Include a measurable target (e.g. "reduce order errors by 30% within 4 weeks").
5. Cite at least one validation source per major recommendation:
   Format → Source: [Org Name] | Insight: [What the research found] | Program: [Grant/link if applicable]
   Acceptable sources: SME Corp Malaysia, MATRADE, MDEC, World Bank SME Report,
   Google ASEAN Digital Economy Report, McKinsey SME Digitalization Study, BNM Financing Schemes.

Do NOT give generic advice.
Do NOT motivate. Diagnose and prescribe.
Do NOT repeat the profile data back to the user.

═══════════════════════════════════════
OUTPUT FORMAT
═══════════════════════════════════════

## 1. Business Diagnosis
**Growth Stage:** [Survival / Stabilizing / Early Scaling / Expansion Ready]
Reason: [2 sentences connecting scores to stage — reference specific answers]

**Top 3 Weaknesses** (each must cite the survey answer that revealed it)
1. [Weakness] — Detected because user selected: "[answer]"
   Impact: [What this costs the business concretely]
2. ...
3. ...

**Top 3 Opportunities** (specific to sector + location)
1. ...

**Top Risk Factors**
1. ...

---

## 2. 90-Day Strategic Roadmap

### Month 1 — Foundation (Weeks 1–4)
Goal: Remove the blockers identified in the diagnosis above.

For each action use this format:
**Action:** [Specific named action]
**Why:** Because you selected "[survey answer]", [problem explanation]
**Tool:** [Exact platform/tool name]
**Steps:**
  1. [micro-step — detailed enough that a first-timer can execute it]
  2. [micro-step]
  3. [micro-step]
  4. [micro-step]
  [add more steps as needed — do not stop at 3 if the task is not fully described]
**Target:** [Measurable outcome in 30 days]
**Source:** [Org] | [Insight] | [Program if applicable]

[3 actions for Month 1]

### Month 2 — Acceleration (Weeks 5–8)
[Same format, 3 actions focused on growth]

### Month 3 — Optimization (Weeks 9–12)
[Same format, 3 actions focused on systems and delegation]

---

## 3. Marketing Execution Plan
Platform focus: $digitalString
Budget level: ${survey.budgetPlan?.label}
Available time: ${survey.weeklyCommitment?.label}

${survey.budgetPlan == BudgetPlan.zeroDollar ? '''
ZERO-BUDGET STRATEGY:
- Organic platform tactics
- Partnership and community growth
- Free government digital programs (e.g. MDEC SME Digitalization Grant)
''' : '''
PAID STRATEGY:
- Platform ad recommendations with budget allocation
- Target audience parameters for ${survey.sector} in ${survey.location}
- Expected ROAS benchmarks for this sector
'''}

Weekly Content Calendar (based on ${survey.weeklyCommitment?.label} availability):
| Day       | Platform | Content Type | Topic Example |
|-----------|----------|-------------|---------------|
[Fill with realistic schedule — do not exceed their time capacity]

---

## 4. KPI Dashboard
[5 KPIs specific to ${survey.sector} — not generic business KPIs]

| KPI | Formula | Weekly Check | Monthly Target | 90-Day Benchmark |
|-----|---------|-------------|----------------|------------------|

---

## 5. Supply Chain Strategy
Supply chain type: ${survey.supplyChain?.label}
${survey.supplyChain == SupplyChain.importHeavy ? '''
Include:
- Currency risk management (USD/MYR hedging tactics for SMEs)
- Buffer stock calculation formula
- Alternative local supplier sourcing strategy
''' : '''
Include:
- Local supplier negotiation tactics
- Margin improvement opportunities
- Inventory efficiency recommendations
'''}

---

$goalSection

---

## 7. Evidence & Source Validation
For each major recommendation above, list:
**Recommendation:** [Name]
**Source:** [Org or Report]
**Key Insight:** [What the data says]
**Why it applies:** [Direct link to this business profile]
**Access:** [URL or program name]

[Minimum 4 sources]

---

## 8. Weekly Time Allocation
Based on: ${survey.weeklyCommitment?.label} per week

| Activity              | Hours/Week | Priority | Focus |
|-----------------------|-----------|----------|-------|
| Operations            | ...       | ...      | ...   |
| Marketing             | ...       | ...      | ...   |
| Customer Development  | ...       | ...      | ...   |
| Strategy & Learning   | ...       | ...      | ...   |

Week 1–4 priority: [One sentence]
Week 5–8 priority: [One sentence]  
Week 9–12 priority: [One sentence]
''';
  }

  // ─── Constraint block ─────────────────────────────────────────────────────

  static String _buildConstraints(SurveyModel survey, int digitalScore) {
    final List<String> c = [];

    if (digitalScore < 4) {
      c.add('⚠ LOW DIGITAL MATURITY ($digitalScore/10): All recommendations must prioritize digitization BEFORE scaling. Do not recommend paid ads or export until basic digital tracking is in place.');
    }
    if (survey.teamSize <= 3) {
      c.add('⚠ MICRO TEAM (${survey.teamSize} people): Avoid multi-track strategies. Recommend single highest-leverage actions only. No complex automation or delegation frameworks.');
    }
    if (survey.weeklyCommitment == WeeklyCommitment.lessThan5) {
      c.add('⚠ VERY LIMITED TIME (< 5 hrs/week): Limit entire roadmap to the 3 highest-impact actions only. Everything else is secondary.');
    }
    if (survey.budgetPlan == BudgetPlan.zeroDollar) {
      c.add('⚠ ZERO BUDGET: Only recommend free tools, organic strategies, and government grant pathways. No paid tools, no ad spend.');
    }
    if (survey.supplyChain == SupplyChain.importHeavy) {
      c.add('⚠ IMPORT-HEAVY SUPPLY CHAIN: Include currency risk management and buffer stock strategy in Month 1.');
    }
    if (!survey.hasAuditedStatements &&
        survey.primaryGoal == PrimaryGoal.getInvestmentReady) {
      c.add('⚠ NO AUDITED ACCOUNTS + INVESTMENT GOAL: Financial documentation must be Step 1 of the entire roadmap. Nothing else matters until this is addressed.');
    }

    return c.isEmpty ? 'No special constraints detected.' : c.join('\n');
  }

  // ─── Goal section ─────────────────────────────────────────────────────────

  static String _buildGoalSection(SurveyModel survey) {
    switch (survey.primaryGoal) {
      case PrimaryGoal.exportAsean:
        return '''
## 6. Export to ASEAN — Execution Plan
Because your goal is ASEAN export, this section replaces generic growth advice.

**Market Entry Preparation:**
1. ...

**Certification & Compliance Checklist:**
- Halal certification (JAKIM) if F&B sector
- SIRIM product certification if manufacturing
- MATRADE Exporters Registry registration

**Distribution Strategy:**
- Recommended entry markets based on ${survey.sector} demand signals
- Channel options: distributor vs. direct e-commerce (Lazada, Shopee cross-border)

**MATRADE Programs to Apply:**
- Market Development Grant (MDG) — covers 50% of export promotion costs
- eTRADE Programme — subsidized e-marketplace onboarding

**Source:** MATRADE | Export acceleration for Malaysian SMEs | matrade.gov.my
''';

      case PrimaryGoal.getInvestmentReady:
        return '''
## 6. Investment Readiness — Execution Plan
Because your goal is investment readiness, this section is your pre-funding checklist.

**Financial Clarity Checklist:**
${survey.hasAuditedStatements ? '✅ Audited statements: Present' : '❌ Audited statements: Missing — this is your #1 blocker. Engage a registered auditor immediately.'}
- [ ] 12 months bank statements organized
- [ ] Revenue & cost breakdown by product/service
- [ ] Cap table (if co-founders exist)
- [ ] Clear use-of-funds statement

**Metrics Investors Expect for ${survey.sector}:**
- Monthly Recurring Revenue (MRR) or equivalent
- Customer Acquisition Cost (CAC) vs Lifetime Value (LTV)
- Gross margin percentage
- Month-over-month growth rate

**Pitch Preparation Framework:**
1. Problem & market size (with ASEAN data)
2. Solution & differentiation
3. Traction evidence (even small numbers count)
4. Team slide
5. Funding ask with 18-month runway plan

**Programs:**
- SME Corp Malaysia — Business Accelerator Programme (BAP)
- Cradle Fund — CIP Spark for early-stage
- MAVCAP — for tech-enabled businesses
''';

      case PrimaryGoal.expandLocal:
        return '''
## 6. Local Market Expansion — Execution Plan
Because your goal is local market growth in ${survey.location}:

**Hyperlocal Customer Acquisition:**
- Google Business Profile optimization (free, high-ROI for local search)
- Neighbourhood WhatsApp community engagement strategy
- Referral program structure: [specific mechanics for ${survey.sector}]

**Local Partnership Strategy:**
- Complementary business cross-promotion
- Local event or market participation calendar

**Source:** Google Malaysia SME Digital Adoption Report | 60% of local searches lead to a business visit within 24 hours
''';

      case PrimaryGoal.improveOps:
        return '''
## 6. Operations Improvement — Execution Plan
Because your goal is operational efficiency:

**Process Audit (Week 1):**
- Map your top 3 most time-consuming daily tasks
- Identify the single biggest source of errors or delays

**Quick-Win Digitization:**
- If tracking = ${survey.salesTracking?.label}: [specific tool recommendation]
- Standard Operating Procedure (SOP) creation template

**Cost Reduction Targets:**
- Labor efficiency: [specific to team size ${survey.teamSize}]
- Waste reduction: [specific to ${survey.sector}]
''';

      default:
        return '''
## 6. General Growth Strategy
Focus on the roadmap above. No specific goal section applies.
''';
    }
  }

  // ─── JSON milestone prompt (the one that feeds the roadmap cards) ─────────

  static String buildJsonSystemPrompt(SurveyModel survey) {
    final rules = _buildJsonRules(survey);
    final resourceCatalogue = _buildCountryResourceCatalogue(survey.location);

    return '''
You are a logic engine for a business roadmap app.
Your ONLY output is a raw JSON array. Nothing else.

STRICT OUTPUT RULES:
- Start your response with [ and end with ]
- No markdown, no code fences, no explanation before or after
- No newlines inside string values — use spaces only
- No special characters that break JSON (no unescaped quotes inside strings)
- All string values must be on a single line

Business Context:
- Business: ${survey.businessName}
- Sector: ${survey.sector}
- Location: ${survey.location}
- Goal: ${survey.primaryGoal?.label}
- Tracking: ${survey.salesTracking?.label}
- Audit: ${survey.hasAuditedStatements ? 'Yes' : 'No'}
- Budget: ${survey.budgetPlan?.label}
- Team: ${survey.teamSize} people
- Time: ${survey.weeklyCommitment?.label}
- Supply Chain: ${survey.supplyChain?.label}
- Digital Platforms: ${survey.digitalPresence.isEmpty ? 'None' : survey.digitalPresence.join(', ')}

Tailoring Rules (MUST follow in order):
$rules

════════════════════════════════════════
STEPS GENERATION RULES — CRITICAL
════════════════════════════════════════
- Each milestone's "steps" array MUST contain as many steps as the task genuinely requires.
- MINIMUM 5 steps per milestone. There is NO maximum.
- Complex milestones (e.g. export registration, financial audit, supply chain setup) 
  should have 7–12 steps.
- Each step must be a COMPLETE, SPECIFIC, ACTIONABLE instruction that a 
  first-time founder can follow independently.
- Do NOT summarise multiple actions into one step.
- Do NOT stop at 3 steps because it looks clean — completeness beats brevity.
- Example of a BAD step: "Set up your accounting software"
- Example of GOOD steps for the same action:
    "Step 1: Go to wave.com and click Get Started for Free to create your account",
    "Step 2: Enter your business name ${survey.businessName} and select ${survey.sector} as your industry",
    "Step 3: Connect your business bank account using the bank sync feature under Accounting > Banking",
    "Step 4: Import your last 3 months of transactions using the CSV upload option",
    "Step 5: Create your first invoice template under Sales > Invoices > New Invoice",
    "Step 6: Set up one income category and one expense category that matches your main revenue stream",
    "Step 7: Run the Profit and Loss report under Reports to see your baseline financial position"

════════════════════════════════════════
RESOURCES GENERATION RULES — CRITICAL
════════════════════════════════════════
- Every milestone MUST include a "resources" array with 2–3 entries.
- Resources MUST be from the country catalogue provided below for ${survey.location}.
- Pick the 2–3 resources that are MOST RELEVANT to the specific milestone topic.
- If the milestone is about digitisation → pick digital grants.
- If the milestone is about export → pick export grants/programmes.
- If the milestone is about financing → pick loan or credit guarantee resources.
- If the milestone is about operations → pick free advisory or accelerator resources.
- Do NOT repeat the same resource across more than 2 milestones.
- Each resource object must follow this exact structure (all fields on one line, no newlines):

  {
    "name": "Resource name",
    "type": "Grant or Loan or Free Service or Guarantee or Programme",
    "provider": "Organisation name",
    "eligibility": "Who qualifies in one sentence",
    "maxAmount": "Maximum funding or benefit amount",
    "processingTime": "Typical time to receive",
    "highlight": "One sentence on what makes this the best fit for this milestone",
    "url": "https://official-website.com"
  }

$resourceCatalogue

════════════════════════════════════════
ALTERNATIVE STEPS RULES — CRITICAL
════════════════════════════════════════
- Every milestone MUST include an "alternativeSteps" array.
- Alternative steps are a DIFFERENT ROUTE to achieve the same milestone outcome.
- Use these scenarios to decide what goes in alternativeSteps:
    * If the main steps require a paid tool → alternative uses a free tool
    * If the main steps require visiting a government office → alternative is fully online
    * If the main steps require a bank loan → alternative uses a grant or bootstrapped method
    * If the main steps require technical skills → alternative uses a no-code/manual method
- Minimum 3 alternative steps. Maximum 8.
- Start each step with "Alt Step X:" prefix.
- Each alternative step must be as specific and actionable as the main steps.
- Example for a "Digitize Sales Tracking" milestone:
    Main steps use Wave accounting (free desktop app).
    Alternative steps:
    "Alt Step 1: If Wave is unavailable in your region open Google Sheets at sheets.google.com and create a new spreadsheet named Sales Tracker",
    "Alt Step 2: Create columns: Date, Customer Name, Product or Service, Amount, Payment Method, Status",
    "Alt Step 3: Each day enter every transaction row by row — take 5 minutes at end of day",
    "Alt Step 4: At end of each week use the SUM formula in a totals row to calculate weekly revenue",
    "Alt Step 5: Share the sheet with your accountant or business partner via the Share button"

════════════════════════════════════════
RESOURCES GENERATION — MUST HAVE 2–3 ENTRIES
════════════════════════════════════════
- EVERY milestone MUST have EXACTLY 2 or 3 resources in the array. Never 0, never 1.
- If you cannot find 3 perfectly matching resources from the catalogue, include the
  closest 2–3 available for ${survey.location} — better to include a slightly less 
  perfect match than to return only 1.
- Every resource object MUST have ALL 8 fields populated with real values — never 
  leave maxAmount or processingTime as "See website". Use the catalogue values.

════════════════════════════════════════
RELEVANCE REASON RULES
════════════════════════════════════════
- Every milestone MUST include a "relevanceReason" field.
- This field explains in 2–3 sentences WHY this milestone specifically matters 
  for ${survey.businessName} based on their survey answers.
- Reference the actual survey answer that triggered this milestone.
- Example: "Because you selected paper-based sales tracking, you currently have 
  no financial visibility. Without digitising this first, you cannot qualify for 
  any government grant or bank loan. Fixing this now unlocks every other milestone."

════════════════════════════════════════
RETURN EXACTLY THIS STRUCTURE — 5 MILESTONES
════════════════════════════════════════
[
  {
    "title": "Max 5 words",
    "description": "One sentence. No quotes inside. No newlines.",
    "weekLabel": "Week 1",
    "emoji": "📱",
    "xp": 100,
    "tool": "Specific tool name",
    "toolUrl": "https://example.com",
    "estimatedTime": "2 hours",
    "source": "SME Corp Malaysia",
    "sourceInsight": "One sentence. No quotes inside. No newlines.",
    "relevanceReason": "2-3 sentences explaining why this matters for this specific business based on their survey answers. No newlines.",
    "steps": [
      "Step 1: very specific action — no newlines",
      "Step 2: very specific action — no newlines",
      "Step 3: very specific action — no newlines",
      "Step 4: very specific action — no newlines",
      "Step 5: very specific action — no newlines",
      "Step 6 onward as needed — do not stop until task is FULLY described"
    ],
    "alternativeSteps": [
      "Alt Step 1: alternative route if main steps are blocked — no newlines",
      "Alt Step 2: continue alternative route — no newlines",
      "Alt Step 3: complete the alternative route — no newlines"
    ],
    "resources": [
      {
        "name": "Resource name from country catalogue",
        "type": "Grant",
        "provider": "Provider organisation name",
        "eligibility": "Who qualifies in one sentence — no newlines",
        "maxAmount": "Exact amount e.g. RM 5000 — never See website",
        "processingTime": "Exact time e.g. 4-6 weeks — never See website",
        "highlight": "Why this resource fits this specific milestone in one sentence",
        "url": "https://official-url.com"
      },
      {
        "name": "Second resource — always include at least 2",
        "type": "Loan",
        "provider": "Provider name",
        "eligibility": "Eligibility in one sentence",
        "maxAmount": "Exact amount",
        "processingTime": "Exact time",
        "highlight": "Why this fits this milestone",
        "url": "https://url.com"
      },
      {
        "name": "Third resource — include when available",
        "type": "Free Service",
        "provider": "Provider name",
        "eligibility": "Eligibility in one sentence",
        "maxAmount": "Free or subsidised",
        "processingTime": "Immediate or timeframe",
        "highlight": "Why this fits this milestone",
        "url": "https://url.com"
      }
    ]
  }
]
''';
  }

  // ─── JSON tailoring rules ─────────────────────────────────────────────────

  static String _buildJsonRules(SurveyModel survey) {
    final rules = <String>[];
    int stepNum = 1;

    if (survey.salesTracking == SalesTracking.paper) {
      rules.add('Milestone $stepNum: Title MUST be "Digitize Sales Tracking". '
          'Description must name a specific free app (e.g. Wave, StoreHub Lite). '
          'Steps must walk through full account setup, bank connection, and first report. '
          'Minimum 7 steps.');
      stepNum++;
    }

    if (!survey.hasAuditedStatements &&
        survey.primaryGoal == PrimaryGoal.getInvestmentReady) {
      rules.add('Milestone $stepNum: Title MUST be "Get Audited Financial Statements". '
          'Description must mention engaging a registered auditor and SME Corp BAP program. '
          'Steps must cover finding an auditor, document preparation, timeline and submission. '
          'Minimum 6 steps.');
      stepNum++;
    } else if (!survey.hasAuditedStatements) {
      rules.add('Milestone $stepNum: Title MUST be "Organize Financial Records". '
          'Description must mention 12 months of bank statements. '
          'Steps must be granular: listing, sorting, categorising and storing documents. '
          'Minimum 5 steps.');
      stepNum++;
    }

    if (survey.supplyChain == SupplyChain.importHeavy) {
      rules.add('Milestone $stepNum: Title MUST be "Build Import Buffer Stock Plan". '
          'Description must mention 30-day buffer stock and currency hedging. '
          'Steps must cover calculating buffer quantities, opening a hedging account and finding backup suppliers. '
          'Minimum 7 steps.');
      stepNum++;
    }

    if (survey.primaryGoal == PrimaryGoal.exportAsean) {
      rules.add('Milestone $stepNum: Must include "Register with MATRADE Exporters Registry" '
          'as the core action. Mention MDG grant. '
          'Steps must walk through the full MATRADE registration process end-to-end. '
          'Minimum 8 steps.');
      stepNum++;
    } else if (survey.primaryGoal == PrimaryGoal.getInvestmentReady) {
      rules.add('Milestone $stepNum: Must include building a pitch deck as the core action. '
          'Mention Cradle Fund or MAVCAP as funding targets. '
          'Steps must cover each slide of the deck individually. '
          'Minimum 8 steps.');
      stepNum++;
    }

    if (survey.digitalPresence.isEmpty ||
        survey.digitalPresence.contains('None')) {
      rules.add('Milestone $stepNum: Must address zero digital presence. '
          'Recommend Google Business Profile as first free step. '
          'Steps must cover full profile creation, photo upload, category selection and first post. '
          'Minimum 6 steps.');
      stepNum++;
    }

    while (stepNum <= 5) {
      rules.add('Milestone $stepNum: Generate a context-specific action for '
          '${survey.sector} sector targeting ${survey.primaryGoal?.label}. '
          'Steps must be detailed enough for independent execution. Minimum 5 steps.');
      stepNum++;
    }

    return rules.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');
  }

  // ─── Scoring logic ────────────────────────────────────────────────────────

  static int _calculateDigitalScore(SurveyModel s) {
    int score = 0;
    if (s.digitalPresence.contains('Own Website')) score += 3;
    if (s.digitalPresence.contains('WhatsApp')) score += 2;
    if (s.digitalPresence.contains('Shopee') ||
        s.digitalPresence.contains('TikTok Shop')) score += 2;
    if (s.digitalPresence.contains('Facebook') ||
        s.digitalPresence.contains('Instagram')) score += 1;
    return score.clamp(0, 10);
  }

  static int _calculateOpsScore(SurveyModel s) {
    int score = 0;
    switch (s.salesTracking) {
      case SalesTracking.paper: score = 3; break;
      case SalesTracking.excel: score = 6; break;
      case SalesTracking.app:   score = 9; break;
      default: score = 2;
    }
    if (s.hasAuditedStatements) score += 1;
    return score.clamp(0, 10);
  }

  static int _calculateExportScore(SurveyModel s, int opsScore, int digitalScore) {
    int score = 0;
    if (s.primaryGoal == PrimaryGoal.exportAsean) score += 3;
    if (s.hasAuditedStatements) score += 3;
    if (opsScore > 7) score += 2;
    if (digitalScore > 5) score += 2;
    return score.clamp(0, 10);
  }

  static int _calculateScaleScore(SurveyModel s, int opsScore) {
    int score = 0;
    if (s.budgetPlan == BudgetPlan.investmentReady) score += 3;
    if (s.teamSize > 5) score += 2;
    if (opsScore > 6) score += 3;
    if (s.weeklyCommitment == WeeklyCommitment.moreThan20) score += 2;
    return score.clamp(0, 10);
  }
}
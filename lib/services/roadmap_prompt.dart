import '../model/survey_model.dart';

class RoadmapPromptBuilder {
  
  /// Main function to generate the full prompt string
static String buildSystemPrompt(SurveyModel survey) {
  final digitalScore = _calculateDigitalScore(survey);
  final opsScore = _calculateOpsScore(survey);
  final exportScore = _calculateExportScore(survey, opsScore, digitalScore);
  final scaleScore = _calculateScaleScore(survey, opsScore);

  final digitalString = survey.digitalPresence.isEmpty
      ? 'None'
      : survey.digitalPresence.join(', ');

  // Derive human-readable constraint warnings BEFORE the output format
  final constraints = _buildConstraints(survey, digitalScore);
  
  // Derive the goal-specific section dynamically
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
2. Include numbered micro-steps (3–5 steps) the founder can execute immediately.
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
  1. [micro-step]
  2. [micro-step]
  3. [micro-step]
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

/// Build constraint block based on survey answers
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
  if (!survey.hasAuditedStatements && survey.primaryGoal == PrimaryGoal.getInvestmentReady) {
    c.add('⚠ NO AUDITED ACCOUNTS + INVESTMENT GOAL: Financial documentation must be Step 1 of the entire roadmap. Nothing else matters until this is addressed.');
  }
  
  return c.isEmpty ? 'No special constraints detected.' : c.join('\n');
}

/// Build goal-specific section dynamically so every goal gets a tailored section
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

static String buildJsonSystemPrompt(SurveyModel survey) {
  // Build ALL tailoring rules dynamically from survey answers
  final rules = _buildJsonRules(survey);
  
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

Return EXACTLY this structure with 5 items:
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
    "steps": [
      "Step 1: specific action with no newlines",
      "Step 2: specific action with no newlines",
      "Step 3: ... (Add as many as needed)"
    ]
  }
]
''';
}

static String _buildJsonRules(SurveyModel survey) {
  final rules = <String>[];
  int stepNum = 1;

  // Financial visibility is always highest priority
  if (survey.salesTracking == SalesTracking.paper) {
    rules.add('Step $stepNum: Title MUST be "Digitize Sales Tracking". '
        'Description must name a specific free app (e.g. Wave, StoreHub Lite).');
    stepNum++;
  }

  // Investment goal blockers first
  if (!survey.hasAuditedStatements && 
      survey.primaryGoal == PrimaryGoal.getInvestmentReady) {
    rules.add('Step $stepNum: Title MUST be "Get Audited Financial Statements". '
        'Description must mention engaging a registered auditor and SME Corp BAP program.');
    stepNum++;
  } else if (!survey.hasAuditedStatements) {
    rules.add('Step $stepNum: Title MUST be "Organize Financial Records". '
        'Description must mention 12 months of bank statements.');
    stepNum++;
  }

  // Supply chain risk
  if (survey.supplyChain == SupplyChain.importHeavy) {
    rules.add('Step $stepNum: Title MUST be "Build Import Buffer Stock Plan". '
        'Description must mention 30-day buffer stock and currency hedging.');
    stepNum++;
  }

  // Goal-specific milestone
  if (survey.primaryGoal == PrimaryGoal.exportAsean) {
    rules.add('Step $stepNum: Must include "Register with MATRADE Exporters Registry" '
        'as a named action. Mention MDG grant.');
    stepNum++;
  } else if (survey.primaryGoal == PrimaryGoal.getInvestmentReady) {
    rules.add('Step $stepNum: Must include building a pitch deck. '
        'Mention Cradle Fund or MAVCAP as funding targets.');
    stepNum++;
  }

  // Digital gap
  if (survey.digitalPresence.isEmpty || survey.digitalPresence.contains('None')) {
    rules.add('Step $stepNum: Must address zero digital presence. '
        'Recommend Google Business Profile as first free step.');
    stepNum++;
  }

  // Fill remaining steps generically but with sector context
  while (stepNum <= 5) {
    rules.add('Step $stepNum: Generate a context-specific action for '
        '${survey.sector} sector targeting ${survey.primaryGoal?.label}.');
    stepNum++;
  }

  return rules.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');
}

  // ─── Scoring Logic ──────────────────────────────────────────────────────────

  static int _calculateDigitalScore(SurveyModel s) {

  s.digitalPresence.length;
  
  int score = 0;
  if (s.digitalPresence.contains('Own Website')) score += 3;      // High value
  if (s.digitalPresence.contains('WhatsApp')) score += 2;         // High usage
  if (s.digitalPresence.contains('Shopee') || 
      s.digitalPresence.contains('TikTok Shop')) score += 2;      // Revenue-generating
  if (s.digitalPresence.contains('Facebook') || 
      s.digitalPresence.contains('Instagram')) score += 1;        // Awareness only
  
  return score.clamp(0, 10);
}

  static int _calculateOpsScore(SurveyModel s) {
    int score = 0;
    s.salesTracking == SalesTracking.app ? 10 : 5;
    // Base score on tracking method
    switch (s.salesTracking) {
      case SalesTracking.paper: score = 3; break;
      case SalesTracking.excel: score = 6; break;
      case SalesTracking.app:   score = 9; break;
      default: score = 2;
    }
    // Bonus for audited statements
    if (s.hasAuditedStatements) score += 1;
    return score.clamp(0, 10);
  }

  static int _calculateExportScore(SurveyModel s, int opsScore, int digitalScore) {
    int score = 0;
    if (s.primaryGoal == PrimaryGoal.exportAsean) score += 3;
    if (s.hasAuditedStatements) score += 3;
    if (opsScore > 7) score += 2; // Need strong ops to export
    if (digitalScore > 5) score += 2; // Need digital presence
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

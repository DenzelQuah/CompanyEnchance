import '../model/survey_model.dart';

class RoadmapPromptBuilder {
  
  /// Main function to generate the full prompt string
  static String buildSystemPrompt(SurveyModel survey) {

    // 1. Calculate Internal Scores
    final digitalScore = _calculateDigitalScore(survey);
    final opsScore = _calculateOpsScore(survey);
    final exportScore = _calculateExportScore(survey, opsScore, digitalScore);
    final scaleScore = _calculateScaleScore(survey, opsScore);

    // 2. Format Lists for display
    final digitalString = survey.digitalPresence.isEmpty 
        ? 'None'
        : survey.digitalPresence.join(', ');

    // 3. Construct the Prompt
    return '''
You are a senior MSME Growth Strategist and ASEAN Market Advisor.
Generate a structured 90-day business growth strategy.
**User Profile:**
- Business: ${survey.businessName}
- Sector: ${survey.sector}
- Goal: ${survey.primaryGoal?.label}
- Current Ops: ${survey.salesTracking?.label} (Score: $opsScore/10)
- Digital Level: $digitalScore/10
- Budget: ${survey.budgetPlan?.label}
- Platforms: $digitalString

Your role is to generate a structured, realistic, and execution-focused 90-day business roadmap.

Do NOT give generic advice.
Do NOT give motivational content.
Give structured, actionable, measurable steps.

Use sector-specific KPIs and terminology.
Use country-specific growth context when relevant.
Adapt strategy based on budget level, supply chain type, digital maturity, and weekly commitment.

Output must be structured in sections with clear headers.

Business Name: ${survey.businessName}
Sector: ${survey.sector}
Location: ${survey.location}
Primary Goal: ${survey.primaryGoal?.label ?? 'General Growth'}

Sales Tracking Method: ${survey.salesTracking?.label ?? 'Unknown'}
Team Size: ${survey.teamSize}
Weekly Commitment: ${survey.weeklyCommitment?.label ?? 'Unknown'}
Budget Type: ${survey.budgetPlan?.label ?? 'Unknown'}
Supply Chain Type: ${survey.supplyChain?.label ?? 'Unknown'}
Digital Platforms: $digitalString

Internal Scoring:
Digital Level: $digitalScore/10
Operational Maturity: $opsScore/10
Export Readiness: $exportScore/10
Scalability Readiness: $scaleScore/10

Generate a structured business growth roadmap using the following format:

1. Business Diagnosis Summary
   - Current Growth Stage
   - Top 3 Weaknesses
   - Top 3 Opportunities
   - Top Risk Factors

2. 90-Day Strategic Roadmap
   - Month 1: Foundation
   - Month 2: Acceleration
   - Month 3: Optimization
   Each month must contain specific weekly action items.

3. Marketing Execution Plan
   - Content posting frequency based on weekly commitment
   - Platform-specific strategy
   - Example content themes
   - If budget = Investment-Ready, include paid ads strategy.
   - If budget = Zero-Dollar, focus on organic and partnerships.

4. Financial & KPI Dashboard
   - 5 KPIs specific to the sector
   - What to track weekly
   - What to track monthly

5. Supply Chain Strategy Adjustment
   - Risk mitigation strategy
   - Margin improvement suggestions

6. If Goal = Export ASEAN
   Include:
   - Market entry preparation steps
   - Certification & compliance considerations
   - Distribution strategy

7. If Goal = Get Investment-Ready
   Include:
   - Financial clarity checklist
   - Metrics investors expect
   - Pitch preparation structure

8. Weekly Time Allocation Breakdown
   Show how the founder should distribute time based on:
   ${survey.weeklyCommitment?.label}

Be concise but strategic.
Avoid fluff.
Focus on execution.
Write in structured bullet format.
Use measurable targets.
Include estimated percentage improvement where possible.

If Digital Level < 4:
Prioritize digitization before scaling.

If Team Size < 3:
Avoid complex automation.

If Supply Chain = Import Heavy:
Include currency and buffer stock strategy.

If Weekly Commitment < 5 hours:
Limit roadmap to high-leverage tasks only.
''';
  }

  static String buildJsonSystemPrompt(SurveyModel survey) {
    return '''
You are a logic engine for a business app. 
Generate a tailored 5-step roadmap for this user.
Return ONLY raw JSON. No markdown formatting.

**User Profile:**
- Business: ${survey.businessName}
- Sector: ${survey.sector}
- Goal: ${survey.primaryGoal?.label}
- Tracking: ${survey.salesTracking?.label}
- Audit Status: ${survey.hasAuditedStatements ? "Has Audited Acts" : "No Audit"}

**JSON Schema:**
[
  {
    "title": "Short Title (Max 5 words)",
    "description": "One sentence action item.",
    "weekLabel": "Week 1",
    "emoji": "📱",
    "xp": 100
  }
]

**Tailoring Rules:**
1. If Tracking = "Paper", Step 1 MUST be "Digitize Sales Records".
2. If No Audit, Step 2 MUST be "Upload Bank Statements".
3. If Goal = "Export", the final step MUST be "MATRADE Registration".
4. Generate exactly 5 steps.
''';
  }

  // ─── Scoring Logic ──────────────────────────────────────────────────────────

  static int _calculateDigitalScore(SurveyModel s) {
    int score = 0;
    if (s.digitalPresence.contains('Own Website')) score += 4;
    score += (s.digitalPresence.length * 2); // 2 points per platform
    return score.clamp(0, 10);
  }

  static int _calculateOpsScore(SurveyModel s) {
    int score = 0;
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
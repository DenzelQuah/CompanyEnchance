import '../model/milestone_model.dart';
import '../model/survey_model.dart';

// 1. Define WhyPoint here (or import it if you put it elsewhere)
class WhyPoint {
  final String emoji, title, body;
  const WhyPoint(this.emoji, this.title, this.body);
}

class MilestoneHelpers {

  // ─── YOUR EXISTING MICRO-TASKS LOGIC ────────────────────────────────────────

  static String? _extractExamples(String stepText) {
    final match = RegExp(r'\(e\.?g\.?,?\s*([^)]+)\)').firstMatch(stepText);
    return match?.group(1)?.trim();
  }

  static String? _extractQuotedTool(String stepText) {
    final match = RegExp(r'"([^"]{3,40})"').firstMatch(stepText);
    return match?.group(1)?.trim();
  }

  static String? _extractSubject(String stepText) {
    final match = RegExp(r'\d[\d–-]*\s+\w[\w\s]{3,30}(?=\s+based|\s+from|\s+using|,|\.|$)',
        caseSensitive: false).firstMatch(stepText);
    return match?.group(0)?.trim();
  }

  static List<String> buildMicroTasks(String stepText) {
    final lower = stepText.toLowerCase();
    final examples = _extractExamples(stepText);
    final quoted = _extractQuotedTool(stepText);
    final subject = _extractSubject(stepText);

    if (lower.contains('register') || lower.contains('sign up') || lower.contains('create account')) {
      final platform = examples ?? quoted ?? 'the platform';
      return [
        'Open $platform using the link in Recommended Tool below',
        'Fill in your business name, registration number and contact details',
        'Upload required documents (IC, SSM cert, bank statement if asked)',
        'Submit and screenshot or save your confirmation number',
      ];
    }
    if ((lower.contains('identify') || lower.contains('list') || lower.contains('select')) && examples != null) {
      return [
        'The step has already identified the options: $examples',
        'Open your notes app, Google Doc, or spreadsheet',
        'Write down each option and one reason why it fits your business',
        'Rank them by priority — put the easiest to act on first',
        'Save the list so you can reference it in later steps',
      ];
    }
    if (lower.contains('research') || lower.contains('identify') || lower.contains('find')) {
      final topic = subject ?? examples ?? 'the options for this step';
      return [
        'Open Google or the tool linked in Recommended Tool below',
        'Search specifically for: $topic',
        'Open at least 3 results and note the key details from each',
        'Write your shortlist in a notes app or spreadsheet',
        'Pick the one best fit and note your reasoning',
      ];
    }
    if (lower.contains('go to') || lower.contains('visit') || lower.contains('open the')) {
      final destination = quoted ?? examples ?? 'the website in Recommended Tool below';
      return [
        'Open $destination in your browser',
        'Find the specific section or form mentioned in the step',
        'Complete what the page asks for — do not skip any required fields',
        'Screenshot or save confirmation before closing the page',
      ];
    }
    if (lower.contains('contact') || lower.contains('reach out') || lower.contains('email') || lower.contains('call')) {
      final who = examples ?? subject ?? 'the contact';
      return [
        'Find the correct contact details for $who (website, LinkedIn, or WhatsApp)',
        'Write a 3-sentence message: who you are, what you need, and your ask',
        'Send the message or make the call now — do not draft and delay',
        'Log the date sent and expected reply timeframe in your notes',
      ];
    }
    if (lower.contains('set up') || lower.contains('configure') || lower.contains('install')) {
      final tool = quoted ?? examples ?? 'the tool in Recommended Tool below';
      return [
        'Open $tool using the link in Recommended Tool below',
        'Complete the account creation or onboarding flow',
        'Enter your business name, sector and contact details',
        'Do one test action (create a record, post, or invoice) to confirm it works',
      ];
    }
    if (lower.contains('write') || lower.contains('draft') || lower.contains('prepare') || lower.contains('create a')) {
      final doc = subject ?? examples ?? 'the document';
      return [
        'Open Google Docs, Word, or your notes app',
        'Start with a title and the key sections needed for $doc',
        'Fill in the content — write quickly, fix later',
        'Review once for missing info or errors',
        'Save and share with anyone who needs to see it',
      ];
    }
    if (lower.contains('post') || lower.contains('publish') || lower.contains('upload') || lower.contains('share')) {
      final platform = examples ?? quoted ?? 'the platform';
      return [
        'Prepare your content (image, caption, or file) before opening $platform',
        'Log in and go to the upload or create section',
        'Fill in all required fields — title, description, category',
        'Hit publish and confirm it is publicly visible',
      ];
    }
    if (lower.contains('analys') || lower.contains('review') || lower.contains('check') || lower.contains('track')) {
      final what = subject ?? examples ?? 'the data for this step';
      return [
        'Open the tool or report that contains $what',
        'Look at the numbers — note what is higher or lower than expected',
        'Write 2–3 observations in plain language',
        'Decide on one action you will take based on what you found',
      ];
    }
    if (lower.contains('apply') || lower.contains('submit') || lower.contains('application') || lower.contains('enrol')) {
      final programme = examples ?? subject ?? 'the programme';
      return [
        'Read the eligibility requirements for $programme in the Resources section below',
        'Gather all required documents before starting the form',
        'Fill in the application completely — do not leave fields blank',
        'Submit and immediately save your reference number or confirmation email',
      ];
    }
    if (lower.contains('calculat') || lower.contains('estimat') || lower.contains('forecast')) {
      return [
        'Open a spreadsheet or calculator app',
        'Enter the numbers or data you already have',
        'Apply the formula or method described in the step',
        'Write down the result and what it means for your next decision',
      ];
    }
    return [
      'Re-read the step once to confirm you understand exactly what is needed',
      'Gather any tools, documents or information required',
      'Execute the step completely — do not stop halfway',
      'Verify your result matches what the step asked for before marking done',
    ];
  }

  // ─── ADDED: LOGIC FOR WHY POINTS ─────────────────────────────────────────────

  static List<WhyPoint> buildWhyPoints(MilestoneModel m, SurveyModel s) {
    final points = <WhyPoint>[];
    final lt = m.title.toLowerCase();

    // 1. Goal Alignment
    points.add(WhyPoint('🎯', 'Directly Supports Your Goal',
        'Your goal is "${s.primaryGoal?.label ?? 'business growth'}". '
        'Completing "${m.title}" moves you closer because ${_goalLine(s)}.'));

    // 2. Paper Sales (Operational Blind Spot)
    if (s.salesTracking == SalesTracking.paper &&
        (lt.contains('sales') || lt.contains('digital'))) {
      points.add(const WhyPoint('📋', 'Fixes Your #1 Operational Blind Spot',
          'You track sales on paper. Without digital records you cannot prove revenue '
          'to banks, spot trends, or qualify for any government grant. '
          'SME Corp data shows digitised businesses cut order errors by 27% within 3 months.'));
    }

    // 3. Audited Statements (Investment)
    if (!s.hasAuditedStatements && s.primaryGoal == PrimaryGoal.getInvestmentReady) {
      points.add(const WhyPoint('💼', 'Unlocks Your Path to Investment',
          'Every investor and grant body in ASEAN requires 2 years of audited '
          'financials before reviewing any application. You have none yet — '
          'this milestone removes that single biggest blocker.'));
    }

    // 4. Import Heavy (Currency Risk)
    if (s.supplyChain == SupplyChain.importHeavy &&
        (lt.contains('supply') || lt.contains('import') || lt.contains('buffer'))) {
      points.add(WhyPoint('🚢', 'Protects You From Currency & Stock Risk',
          'Your import-heavy chain exposes ${s.businessName} to exchange-rate swings. '
          'Businesses without buffer stock report 15–30% margin erosion during '
          'currency moves (World Bank SME Trade Finance Report).'));
    }

    // 5. Digital Presence
    if (s.digitalPresence.isEmpty &&
        (lt.contains('digital') || lt.contains('online') || lt.contains('social'))) {
      points.add(WhyPoint('📱', 'You Currently Have Zero Digital Visibility',
          '74% of SME customers in ${s.location} check a business online before '
          'purchasing (Google ASEAN Digital Economy Report 2023). '
          'Every week without a digital presence is measurable lost revenue.'));
    }

    // 6. Export Goal
    if (s.primaryGoal == PrimaryGoal.exportAsean &&
        (lt.contains('export') || lt.contains('matrade') || lt.contains('market'))) {
      points.add(const WhyPoint('🌏', 'Required for ASEAN Market Entry',
          'Foreign buyers and logistics partners require MATRADE registration and '
          'verified export documentation before placing any order. '
          'This milestone is the non-negotiable entry ticket.'));
    }

    // 7. Team Size Fit
    if (s.teamSize <= 3) {
      points.add(WhyPoint('⚡', 'Designed for a ${s.teamSize}-Person Team',
          'Every step fits a micro-team without outside contractors. '
          'Estimated time (${m.estimatedTime}) is compatible with '
          '${s.weeklyCommitment?.label} per week.'));
    }

    // 8. Zero Budget Fit
    if (s.budgetPlan == BudgetPlan.zeroDollar) {
      points.add(WhyPoint('🆓', 'Zero Cost to Complete',
          'Every tool and resource here is free or grant-eligible, matching your '
          'zero-budget constraint. The roadmap was built around organic strategies '
          'and government programmes available in ${s.location}.'));
    }

    // 9. Generic Research Backing
    if (points.length < 2 && m.sourceInsight.isNotEmpty) {
      points.add(WhyPoint('📚', m.source.isNotEmpty ? m.source : 'Research-Backed',
          m.sourceInsight));
    }

    return points.take(4).toList();
  }

  // Helper for goal line text
  static String _goalLine(SurveyModel s) {
    switch (s.primaryGoal) {
      case PrimaryGoal.exportAsean:
        return 'ASEAN buyers require compliant documented suppliers — this builds that credibility';
      case PrimaryGoal.getInvestmentReady:
        return 'investors evaluate execution capability — each milestone is concrete proof';
      case PrimaryGoal.expandLocal:
        return 'local growth requires operational capacity and visibility — this builds both';
      case PrimaryGoal.improveOps:
        return 'operational excellence compounds — every system you build frees your time';
      default:
        return 'it resolves a root-cause blocker identified in your diagnostic';
    }
  }
}
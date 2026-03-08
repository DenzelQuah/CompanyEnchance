// lib/view/milestone_detail_screen.dart
// Performance-optimized: expensive computations cached, no inline withOpacity,
// const constructors everywhere possible, ListView.builder for steps.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/roadmap_controller.dart';
import '../model/app_theme.dart';
import '../model/milestone_model.dart';
import '../model/survey_model.dart';
import 'chatbot_sheet.dart';

// ─── Pre-computed color constants (no withOpacity at runtime) ────────────────
const _kOrangeBg     = Color(0x1AFF9800); // orange 10%
const _kOrangeBorder = Color(0x66FF9800); // orange 40%
const _kBlueBorder   = Color(0x4D1D4ED8); // blue 30%
const _kBorderFaint  = Color(0x99E5E7EB); // border 60%
const _kWhite15      = Color(0x26FFFFFF); // white 15%
const _kPurple50     = Color(0xFFF5F3FF);
const _kPurple100    = Color(0xFFEDE9FE);
const _kPurple200    = Color(0xFFDDD6FE);
const _kPurple300    = Color(0xFFC4B5FD);
const _kPurple700    = Color(0xFF6D28D9);
const _kPurple800    = Color(0xFF5B21B6);
const _kGray50       = Color(0xFFF9FAFB);
const _kGray100      = Color(0xFFF3F4F6);
const _kGray200      = Color(0xFFE5E7EB);

// ─────────────────────────────────────────────────────────────────────────────
// Internal display resource
// ─────────────────────────────────────────────────────────────────────────────

class _DisplayResource {
  final String name, type, provider, eligibility,
               maxAmount, processingTime, highlight, url;
  const _DisplayResource({
    required this.name, required this.type, required this.provider,
    required this.eligibility, required this.maxAmount,
    required this.processingTime, required this.highlight, required this.url,
  });

  factory _DisplayResource.fromEmbedded(MilestoneResource r) => _DisplayResource(
    name:           r.name,
    type:           r.type.isNotEmpty          ? r.type           : 'Resource',
    provider:       r.provider.isNotEmpty      ? r.provider       : r.name,
    eligibility:    r.eligibility,
    maxAmount:      r.maxAmount.isNotEmpty      ? r.maxAmount      : 'See website',
    processingTime: r.processingTime.isNotEmpty ? r.processingTime : 'See website',
    highlight:      r.highlight.isNotEmpty      ? r.highlight      : r.eligibility,
    url:            r.url,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Static ASEAN fallback catalogue
// ─────────────────────────────────────────────────────────────────────────────

const List<_DisplayResource> _kFallback = [
  _DisplayResource(name: 'SME Digitalization Grant', type: 'Grant',
      provider: 'SME Corp Malaysia / MDEC',
      eligibility: 'Malaysian SMEs, min. 60% local ownership',
      maxAmount: 'RM 5,000', processingTime: '4–6 weeks',
      highlight: 'Covers subscription fees for approved digital tools',
      url: 'https://www.smebank.com.my/en/products-services/sme-digitalization-grant'),
  _DisplayResource(name: 'Business Accelerator Programme (BAP)', type: 'Grant',
      provider: 'SME Corp Malaysia',
      eligibility: 'SMEs with min. 2 years operation',
      maxAmount: 'Up to RM 300,000', processingTime: '8–12 weeks',
      highlight: 'Full business development and market expansion support',
      url: 'https://www.smecorp.gov.my/index.php/en/programmes/2015-12-21-08-39-38/business-accelerator-programme'),
  _DisplayResource(name: 'MATRADE Market Development Grant (MDG)', type: 'Grant',
      provider: 'MATRADE',
      eligibility: 'Malaysian exporters registered with MATRADE',
      maxAmount: 'Up to RM 300,000 cumulative', processingTime: '6–8 weeks',
      highlight: 'Reimburses export promotion costs including fairs and e-commerce setup',
      url: 'https://www.matrade.gov.my/en/malaysian-exporters/services-for-exporters/develop-your-export-market/mdg'),
  _DisplayResource(name: 'BNM PENJANA Micro Loan', type: 'Loan',
      provider: 'Bank Negara Malaysia',
      eligibility: 'Micro-enterprises, max 5 employees',
      maxAmount: 'RM 75,000', processingTime: '2–3 weeks',
      highlight: 'Low-interest financing with flexible repayment terms',
      url: 'https://www.bnm.gov.my'),
  _DisplayResource(name: 'MDEC eTRADE Programme', type: 'Grant',
      provider: 'MDEC',
      eligibility: 'Malaysian SMEs in e-commerce',
      maxAmount: 'RM 5,000 per year', processingTime: '3–4 weeks',
      highlight: 'Subsidised onboarding fees for approved e-marketplaces',
      url: 'https://mdec.my/etrade'),
  _DisplayResource(name: 'Enterprise Development Grant (EDG)', type: 'Grant',
      provider: 'Enterprise Singapore',
      eligibility: 'Singapore-registered SMEs, min. 30% local equity',
      maxAmount: 'Up to 50% of qualifying costs', processingTime: '6–8 weeks',
      highlight: 'Covers capability development, innovation and internationalisation',
      url: 'https://www.enterprisesg.gov.sg/financial-support/enterprise-development-grant'),
  _DisplayResource(name: 'Productivity Solutions Grant (PSG)', type: 'Grant',
      provider: 'Enterprise Singapore / IMDA',
      eligibility: 'Singapore-registered SMEs in approved sectors',
      maxAmount: 'Up to 50% of solution cost', processingTime: '4–6 weeks',
      highlight: 'Pre-approved list of digital and automation solutions ready to deploy',
      url: 'https://www.enterprisesg.gov.sg/financial-support/productivity-solutions-grant'),
  _DisplayResource(name: 'SkillsFuture Enterprise Credit (SFEC)', type: 'Credit',
      provider: 'SkillsFuture Singapore',
      eligibility: 'Eligible employers with at least 3 Singapore employees',
      maxAmount: 'SGD 10,000 credit', processingTime: '2–4 weeks',
      highlight: 'Offsets costs of workforce transformation programmes',
      url: 'https://www.skillsfuture.gov.sg/sfec'),
  _DisplayResource(name: 'KUR (Kredit Usaha Rakyat)', type: 'Loan',
      provider: 'Ministry of Finance / State Banks',
      eligibility: 'Indonesian MSMEs with valid business identity',
      maxAmount: 'IDR 500 million (micro tier)', processingTime: '1–2 weeks',
      highlight: 'Subsidised interest rate at 6% per annum for small businesses',
      url: 'https://kur.ekon.go.id'),
  _DisplayResource(name: 'LPEI Export Financing', type: 'Loan',
      provider: 'Indonesia Eximbank (LPEI)',
      eligibility: 'Indonesian exporters, all sectors',
      maxAmount: 'IDR 10 billion+', processingTime: '4–8 weeks',
      highlight: 'Export buyer credit and working capital for exporters',
      url: 'https://www.lpei.go.id/en'),
  _DisplayResource(name: 'PLUT-KUMKM Business Development', type: 'Free Service',
      provider: 'Ministry of Cooperatives & SMEs Indonesia',
      eligibility: 'All Indonesian SMEs',
      maxAmount: 'Free services', processingTime: 'Immediate',
      highlight: 'Free business consulting, training and mentoring centre network',
      url: 'https://www.depkop.go.id'),
  _DisplayResource(name: 'SME Development Bank Soft Loan', type: 'Loan',
      provider: 'SME Development Bank of Thailand',
      eligibility: 'Thai-registered SMEs, max THB 500M annual revenue',
      maxAmount: 'THB 15 million', processingTime: '3–4 weeks',
      highlight: 'Below-market interest rates with flexible collateral options',
      url: 'https://www.smebank.co.th/en'),
  _DisplayResource(name: 'BOI Smart SME Program', type: 'Incentive',
      provider: 'Board of Investment Thailand',
      eligibility: 'Thai SMEs in BOI target industries',
      maxAmount: 'Varies by project', processingTime: '8–12 weeks',
      highlight: 'Tax incentives and investment promotion for priority growth sectors',
      url: 'https://www.boi.go.th'),
  _DisplayResource(name: 'DITP Export Promotion Grant', type: 'Grant',
      provider: 'Department of International Trade Promotion Thailand',
      eligibility: 'Thai exporters and SMEs',
      maxAmount: 'THB 200,000', processingTime: '4–6 weeks',
      highlight: 'Covers trade fair participation and international market development',
      url: 'https://www.ditp.go.th'),
  _DisplayResource(name: 'SME Support Fund Credit Guarantee', type: 'Guarantee',
      provider: 'Vietnam Development Bank',
      eligibility: 'Vietnamese-registered SMEs',
      maxAmount: 'VND 5 billion', processingTime: '3–5 weeks',
      highlight: 'Credit guarantee to help SMEs access commercial bank loans',
      url: 'https://www.vdb.gov.vn'),
  _DisplayResource(name: 'National SME Development Program', type: 'Free Service',
      provider: 'Ministry of Planning & Investment Vietnam',
      eligibility: 'All Vietnamese SMEs',
      maxAmount: 'Free training and consultation', processingTime: 'Immediate',
      highlight: 'Free business registration, legal consultation and market access support',
      url: 'https://business.gov.vn'),
  _DisplayResource(name: 'MSME Credit Guarantee Program', type: 'Guarantee',
      provider: 'Philippine Guarantee Corporation (PhilGuarantee)',
      eligibility: 'Filipino MSMEs with bank accounts',
      maxAmount: 'PHP 5 million', processingTime: '2–4 weeks',
      highlight: 'Guarantee covers 70–80% of bank loan for easier bank approval',
      url: 'https://www.philguarantee.gov.ph'),
  _DisplayResource(name: 'DTI Negosyo Center', type: 'Free Service',
      provider: 'Department of Trade & Industry Philippines',
      eligibility: 'All Filipino SMEs',
      maxAmount: 'Free services', processingTime: 'Walk-in same day',
      highlight: 'One-stop shop for registration, coaching and tech assistance',
      url: 'https://www.dti.gov.ph/negosyo/'),
  _DisplayResource(name: 'SB Corp CARES Loan', type: 'Loan',
      provider: 'Small Business Corporation Philippines',
      eligibility: 'Filipino SMEs affected by economic disruption',
      maxAmount: 'PHP 5 million', processingTime: '2–3 weeks',
      highlight: 'Low-interest loans at 0.5% monthly with a grace period option',
      url: 'https://www.sbcorp.gov.ph'),
];

bool _isCountryMatch(_DisplayResource r, String country) {
  final c = country.toLowerCase();
  final n = r.name.toLowerCase();
  if (c.contains('malaysia') || c.contains('kuala lumpur')) {
    return n.contains('sme digit') || n.contains('bap') || n.contains('matrade') ||
        n.contains('bnm') || n.contains('mdec');
  }
  if (c.contains('singapore')) {
    return n.contains('edg') || n.contains('psg') || n.contains('skillsfuture') ||
        n.contains('enterprise development') || n.contains('productivity solution');
  }
  if (c.contains('indonesia')) {
    return n.contains('kur') || n.contains('lpei') || n.contains('plut');
  }
  if (c.contains('thailand')) {
    return n.contains('sme development bank') || n.contains('boi') || n.contains('ditp');
  }
  if (c.contains('vietnam')) {
    return n.contains('sme support fund') || n.contains('national sme development');
  }
  if (c.contains('philippines')) {
    return n.contains('msme credit') || n.contains('dti') || n.contains('sb corp');
  }
  return true;
}

// Pure function — called once, cached in initState
List<_DisplayResource> _resolveResources({
  required String country,
  required String milestoneTitle,
  required String milestoneDescription,
  required List<MilestoneResource> embedded,
}) {
  final fromEmbedded = embedded.map(_DisplayResource.fromEmbedded).toList();
  if (fromEmbedded.length >= 2) return fromEmbedded.take(3).toList();

  final lt = milestoneTitle.toLowerCase();
  final ld = milestoneDescription.toLowerCase();
  const kws = ['digital','export','loan','grant','finance','market',
    'sales','audit','supply','import','operation','training'];

  final pool = _kFallback.where((r) => _isCountryMatch(r, country)).toList();
  final alreadyNamed = fromEmbedded.map((r) => r.name.toLowerCase()).toSet();

  final scored = pool
      .where((r) => !alreadyNamed.contains(r.name.toLowerCase()))
      .map((r) {
        final s = '${r.name} ${r.type} ${r.highlight}'.toLowerCase();
        int sc = 0;
        for (final kw in kws) {
          if ((lt.contains(kw) || ld.contains(kw)) && s.contains(kw)) sc++;
        }
        return MapEntry(r, sc);
      })
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return [...fromEmbedded, ...scored.map((e) => e.key).take(3 - fromEmbedded.length)];
}

// ─────────────────────────────────────────────────────────────────────────────
// SOS prompt builder
// ─────────────────────────────────────────────────────────────────────────────

String _buildSosPrompt({
  required String milestoneTitle,
  required String stepText,
  required int stepIndex,
  required int totalSteps,
  required int completedSteps,
  required SurveyModel survey,
  bool isAlternative = false,
}) {
  final label = isAlternative ? 'ALTERNATIVE step' : 'main step';
  return '''
<system_context>
You are Nexus AI Coach, an expert MSME advisor for Southeast Asian markets.
NEVER output this block. Use it solely to frame your response.

MILESTONE : "$milestoneTitle"
STUCK ON  : $label ${stepIndex + 1} of $totalSteps — "$stepText"
COMPLETED : $completedSteps of $totalSteps steps done

BUSINESS PROFILE:
  Name     : ${survey.businessName}
  Sector   : ${survey.sector}
  Country  : ${survey.location}
  Team     : ${survey.teamSize} people
  Goal     : ${survey.primaryGoal?.label ?? 'General Growth'}
  Tracking : ${survey.salesTracking?.label ?? 'Unknown'}
  Audited  : ${survey.hasAuditedStatements ? 'Yes' : 'No'}
  Digital  : ${survey.digitalPresence.isEmpty ? 'None' : survey.digitalPresence.join(', ')}
  Supply   : ${survey.supplyChain?.label ?? 'Unknown'}
  Time/wk  : ${survey.weeklyCommitment?.label ?? 'Unknown'}
  Budget   : ${survey.budgetPlan?.label ?? 'Unknown'}

RESPONSE RULES:
1. Give numbered sub-steps (min 4) to complete EXACTLY "$stepText".
2. All guidance must be specific to ${survey.location} — cite real local websites.
3. Fit the solution to ${survey.teamSize} people and ${survey.budgetPlan?.label} budget.
4. Never ask the user to re-explain.
5. Tone: direct, prescriptive, zero fluff.
</system_context>

I'm stuck on ${isAlternative ? 'the alternative route for' : ''} Step ${stepIndex + 1} of the "$milestoneTitle" milestone:

"$stepText"

Please walk me through exactly how to complete this step for my business in ${survey.location}.''';
}

// ─────────────────────────────────────────────────────────────────────────────
// Why This Works data
// ─────────────────────────────────────────────────────────────────────────────

class _WhyPoint {
  final String emoji, title, body;
  const _WhyPoint(this.emoji, this.title, this.body);
}

// Pure function — called once, cached in initState
List<_WhyPoint> _buildWhyPoints(MilestoneModel m, SurveyModel s) {
  final points = <_WhyPoint>[];
  final lt = m.title.toLowerCase();

  points.add(_WhyPoint('🎯', 'Directly Supports Your Goal',
      'Your goal is "${s.primaryGoal?.label ?? 'business growth'}". '
      'Completing "${m.title}" moves you closer because ${_goalLine(s)}.'));

  if (s.salesTracking == SalesTracking.paper &&
      (lt.contains('sales') || lt.contains('digital'))) {
    points.add(const _WhyPoint('📋', 'Fixes Your #1 Operational Blind Spot',
        'You track sales on paper. Without digital records you cannot prove revenue '
        'to banks, spot trends, or qualify for any government grant. '
        'SME Corp data shows digitised businesses cut order errors by 27% within 3 months.'));
  }
  if (!s.hasAuditedStatements && s.primaryGoal == PrimaryGoal.getInvestmentReady) {
    points.add(const _WhyPoint('💼', 'Unlocks Your Path to Investment',
        'Every investor and grant body in ASEAN requires 2 years of audited '
        'financials before reviewing any application. You have none yet — '
        'this milestone removes that single biggest blocker.'));
  }
  if (s.supplyChain == SupplyChain.importHeavy &&
      (lt.contains('supply') || lt.contains('import') || lt.contains('buffer'))) {
    points.add(_WhyPoint('🚢', 'Protects You From Currency & Stock Risk',
        'Your import-heavy chain exposes ${s.businessName} to exchange-rate swings. '
        'Businesses without buffer stock report 15–30% margin erosion during '
        'currency moves (World Bank SME Trade Finance Report).'));
  }
  if (s.digitalPresence.isEmpty &&
      (lt.contains('digital') || lt.contains('online') || lt.contains('social'))) {
    points.add(_WhyPoint('📱', 'You Currently Have Zero Digital Visibility',
        '74% of SME customers in ${s.location} check a business online before '
        'purchasing (Google ASEAN Digital Economy Report 2023). '
        'Every week without a digital presence is measurable lost revenue.'));
  }
  if (s.primaryGoal == PrimaryGoal.exportAsean &&
      (lt.contains('export') || lt.contains('matrade') || lt.contains('market'))) {
    points.add(const _WhyPoint('🌏', 'Required for ASEAN Market Entry',
        'Foreign buyers and logistics partners require MATRADE registration and '
        'verified export documentation before placing any order. '
        'This milestone is the non-negotiable entry ticket.'));
  }
  if (s.teamSize <= 3) {
    points.add(_WhyPoint('⚡', 'Designed for a ${s.teamSize}-Person Team',
        'Every step fits a micro-team without outside contractors. '
        'Estimated time (${m.estimatedTime}) is compatible with '
        '${s.weeklyCommitment?.label} per week.'));
  }
  if (s.budgetPlan == BudgetPlan.zeroDollar) {
    points.add(_WhyPoint('🆓', 'Zero Cost to Complete',
        'Every tool and resource here is free or grant-eligible, matching your '
        'zero-budget constraint. The roadmap was built around organic strategies '
        'and government programmes available in ${s.location}.'));
  }
  if (points.length < 2 && m.sourceInsight.isNotEmpty) {
    points.add(_WhyPoint('📚', m.source.isNotEmpty ? m.source : 'Research-Backed',
        m.sourceInsight));
  }
  return points.take(4).toList();
}

String _goalLine(SurveyModel s) {
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

// ─────────────────────────────────────────────────────────────────────────────
// Micro-task builder  (pure function, called once per step tap)
// ─────────────────────────────────────────────────────────────────────────────

// Extracts parenthesised examples from step text, e.g. "(e.g., Wave, StoreHub)" → "Wave, StoreHub"
String? _extractExamples(String stepText) {
  final match = RegExp(r'\(e\.?g\.?,?\s*([^)]+)\)').firstMatch(stepText);
  return match?.group(1)?.trim();
}

// Extracts a quoted tool/name from step text, e.g. go to "wave.com" → wave.com
String? _extractQuotedTool(String stepText) {
  final match = RegExp(r'"([^"]{3,40})"').firstMatch(stepText);
  return match?.group(1)?.trim();
}

// Returns the specific subject the step is asking about (countries, platforms, docs, etc.)
String? _extractSubject(String stepText) {
  // Numbers + subject: "2-3 priority ASEAN countries" → "2–3 priority ASEAN countries"
  final match = RegExp(r'\d[\d–-]*\s+\w[\w\s]{3,30}(?=\s+based|\s+from|\s+using|,|\.|$)',
      caseSensitive: false).firstMatch(stepText);
  return match?.group(0)?.trim();
}

List<String> _buildMicroTasks(String stepText) {
  final lower   = stepText.toLowerCase();
  final examples = _extractExamples(stepText);   // e.g. "Singapore, Indonesia, Thailand"
  final quoted   = _extractQuotedTool(stepText);  // e.g. "wave.com"
  final subject  = _extractSubject(stepText);     // e.g. "2-3 priority ASEAN countries"

  // ── REGISTER / SIGN UP ────────────────────────────────────────────────────
  if (lower.contains('register') || lower.contains('sign up') || lower.contains('create account')) {
    final platform = examples ?? quoted ?? 'the platform';
    return [
      'Open $platform using the link in Recommended Tool below',
      'Fill in your business name, registration number and contact details',
      'Upload required documents (IC, SSM cert, bank statement if asked)',
      'Submit and screenshot or save your confirmation number',
    ];
  }

  // ── IDENTIFY / LIST with specific content already given ───────────────────
  // Step already names what to identify — skip the "search" step, go straight to recording
  if ((lower.contains('identify') || lower.contains('list') || lower.contains('select')) &&
      examples != null) {
    return [
      'The step has already identified the options: $examples',
      'Open your notes app, Google Doc, or spreadsheet',
      'Write down each option and one reason why it fits your business',
      'Rank them by priority — put the easiest to act on first',
      'Save the list so you can reference it in later steps',
    ];
  }

  // ── RESEARCH without specific answer given ────────────────────────────────
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

  // ── GO TO / VISIT a specific URL or tool ──────────────────────────────────
  if (lower.contains('go to') || lower.contains('visit') || lower.contains('open the')) {
    final destination = quoted ?? examples ?? 'the website in Recommended Tool below';
    return [
      'Open $destination in your browser',
      'Find the specific section or form mentioned in the step',
      'Complete what the page asks for — do not skip any required fields',
      'Screenshot or save confirmation before closing the page',
    ];
  }

  // ── CONTACT / REACH OUT ───────────────────────────────────────────────────
  if (lower.contains('contact') || lower.contains('reach out') || lower.contains('email') || lower.contains('call')) {
    final who = examples ?? subject ?? 'the contact';
    return [
      'Find the correct contact details for $who (website, LinkedIn, or WhatsApp)',
      'Write a 3-sentence message: who you are, what you need, and your ask',
      'Send the message or make the call now — do not draft and delay',
      'Log the date sent and expected reply timeframe in your notes',
    ];
  }

  // ── SET UP / INSTALL a tool ───────────────────────────────────────────────
  if (lower.contains('set up') || lower.contains('configure') || lower.contains('install') ||
      lower.contains('create your') || lower.contains('open your')) {
    final tool = quoted ?? examples ?? 'the tool in Recommended Tool below';
    return [
      'Open $tool using the link in Recommended Tool below',
      'Complete the account creation or onboarding flow',
      'Enter your business name, sector and contact details',
      'Do one test action (create a record, post, or invoice) to confirm it works',
    ];
  }

  // ── WRITE / DRAFT / PREPARE a document ───────────────────────────────────
  if (lower.contains('write') || lower.contains('draft') || lower.contains('prepare') ||
      lower.contains('create a') || lower.contains('build a')) {
    final doc = subject ?? examples ?? 'the document';
    return [
      'Open Google Docs, Word, or your notes app',
      'Start with a title and the key sections needed for $doc',
      'Fill in the content — write quickly, fix later',
      'Review once for missing info or errors',
      'Save and share with anyone who needs to see it',
    ];
  }

  // ── POST / PUBLISH / UPLOAD ───────────────────────────────────────────────
  if (lower.contains('post') || lower.contains('publish') || lower.contains('upload') || lower.contains('share')) {
    final platform = examples ?? quoted ?? 'the platform';
    return [
      'Prepare your content (image, caption, or file) before opening $platform',
      'Log in and go to the upload or create section',
      'Fill in all required fields — title, description, category',
      'Hit publish and confirm it is publicly visible',
    ];
  }

  // ── ANALYSE / REVIEW / CHECK ──────────────────────────────────────────────
  if (lower.contains('analys') || lower.contains('review') || lower.contains('check') ||
      lower.contains('measure') || lower.contains('track')) {
    final what = subject ?? examples ?? 'the data for this step';
    return [
      'Open the tool or report that contains $what',
      'Look at the numbers — note what is higher or lower than expected',
      'Write 2–3 observations in plain language',
      'Decide on one action you will take based on what you found',
    ];
  }

  // ── APPLY / SUBMIT ────────────────────────────────────────────────────────
  if (lower.contains('apply') || lower.contains('submit') || lower.contains('application') ||
      lower.contains('register for') || lower.contains('enrol')) {
    final programme = examples ?? subject ?? 'the programme';
    return [
      'Read the eligibility requirements for $programme in the Resources section below',
      'Gather all required documents before starting the form',
      'Fill in the application completely — do not leave fields blank',
      'Submit and immediately save your reference number or confirmation email',
    ];
  }

  // ── CALCULATE / COMPUTE ───────────────────────────────────────────────────
  if (lower.contains('calculat') || lower.contains('estimat') || lower.contains('forecast')) {
    return [
      'Open a spreadsheet or calculator app',
      'Enter the numbers or data you already have',
      'Apply the formula or method described in the step',
      'Write down the result and what it means for your next decision',
    ];
  }

  // ── DEFAULT — generic completion framework ────────────────────────────────
  return [
    'Re-read the step once to confirm you understand exactly what is needed',
    'Gather any tools, documents or information required',
    'Execute the step completely — do not stop halfway',
    'Verify your result matches what the step asked for before marking done',
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Type helpers (static lookups — no switch overhead at runtime)
// ─────────────────────────────────────────────────────────────────────────────

const _typeColors = <String, Color>{
  'Grant':        Color(0xFF059669),
  'Loan':         AppTheme.blue,
  'Credit':       AppTheme.blue,
  'Guarantee':    Color(0xFF7C3AED),
  'Incentive':    Color(0xFF7C3AED),
  'Free Service': Color(0xFF92400E),
};

const _typeIcons = <String, String>{
  'Grant': '💸', 'Loan': '🏦', 'Credit': '🏦',
  'Guarantee': '🛡', 'Incentive': '🎁', 'Free Service': '📚',
};

Color _typeColor(String type) => _typeColors[type] ?? AppTheme.textMuted;
String _typeIcon(String type)  => _typeIcons[type]  ?? '🔖';

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class MilestoneDetailScreen extends ConsumerStatefulWidget {
  final MilestoneModel milestone;
  final SurveyModel survey;
  final VoidCallback? onComplete;

  const MilestoneDetailScreen({
    super.key,
    required this.milestone,
    required this.survey,
    this.onComplete,
  });

  @override
  ConsumerState<MilestoneDetailScreen> createState() =>
      _MilestoneDetailScreenState();
}

class _MilestoneDetailScreenState extends ConsumerState<MilestoneDetailScreen> {
  late int _currentStep;
  final Set<int> _checkedSteps = {};

  bool _showComparison  = false;
  bool _showAlternative = false;

  // ── Cached expensive computations — computed once in initState ────────────
  late final List<_DisplayResource> _resources;
  late final List<_WhyPoint> _whyPoints;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.milestone.currentStep;
    for (int i = 0; i < _currentStep; i++) _checkedSteps.add(i);

    // Cache — these never change while the screen is open
    _resources = _resolveResources(
      country: widget.survey.location,
      milestoneTitle: widget.milestone.title,
      milestoneDescription: widget.milestone.description,
      embedded: widget.milestone.resources,
    );
    _whyPoints = _buildWhyPoints(widget.milestone, widget.survey);
  }

  // ── Step gating ───────────────────────────────────────────────────────────

  int get _nextAllowedIndex => _checkedSteps.isEmpty
      ? 0
      : (_checkedSteps.toList()..sort()).last + 1;

  bool get _allDone =>
      _checkedSteps.length == widget.milestone.steps.length;

  void _saveProgress() {
    int cons = 0;
    for (int i = 0; i < widget.milestone.steps.length; i++) {
      if (_checkedSteps.contains(i)) cons++; else break;
    }
    _currentStep = cons;
    ref.read(roadmapControllerProvider.notifier)
        .updateMilestoneProgress(widget.milestone.id, cons);
  }

  void _handleStepTap(int index, String stepText) {
    if (index > _nextAllowedIndex) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🔒 Complete Step ${_nextAllowedIndex + 1} first.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF374151),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    if (_checkedSteps.contains(index)) {
      final maxChecked = (_checkedSteps.toList()..sort()).last;
      if (index == maxChecked) {
        setState(() { _checkedSteps.remove(index); _saveProgress(); });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠️ You can only undo the most recently completed step.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    _showGuidedTaskSheet(index, stepText);
  }

  void _showGuidedTaskSheet(int index, String stepText) {
    // _buildMicroTasks is pure and cheap — OK to call here
    final microTasks = _buildMicroTasks(stepText);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GuidedTaskSheet(
        stepIndex: index,
        stepText: stepText,
        microTasks: microTasks,
        totalSteps: widget.milestone.steps.length,
        location: widget.survey.location,
        onSosPressed: () { Navigator.pop(ctx); _openSos(index, stepText); },
        onConfirmedDone: () {
          Navigator.pop(ctx);
          setState(() { _checkedSteps.add(index); _saveProgress(); });
          _celebrate(index);
        },
      ),
    );
  }

  void _celebrate(int index) {
    final done  = _checkedSteps.length;
    final total = widget.milestone.steps.length;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        done == total
            ? '🎉 All steps complete! Claim your XP below.'
            : '✅ Step ${index + 1} done — $done/$total complete!',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: done == total ? AppTheme.green : AppTheme.blue,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _openSos(int stepIndex, String stepText, {bool isAlternative = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChatbotSheet(
        initialQuery: _buildSosPrompt(
          milestoneTitle: widget.milestone.title,
          stepText: stepText,
          stepIndex: stepIndex,
          totalSteps: widget.milestone.steps.length,
          completedSteps: _checkedSteps.length,
          survey: widget.survey,
          isAlternative: isAlternative,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final m      = widget.milestone;
    final survey = widget.survey;
    final hasAlt = m.alternativeSteps.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final nextText = _nextAllowedIndex < m.steps.length
              ? m.steps[_nextAllowedIndex]
              : 'completing this milestone';
          _openSos(_nextAllowedIndex, nextText);
        },
        backgroundColor: Colors.orange,
        elevation: 4,
        icon: const Text('🆘', style: TextStyle(fontSize: 16)),
        label: const Text('SOS Help',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(m.weekLabel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppTheme.textMuted)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _allDone ? AppTheme.greenPale : AppTheme.bluePale,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_checkedSteps.length}/${m.steps.length} steps',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: _allDone ? AppTheme.green : AppTheme.blue)),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Fixed header sections (hero + progress + step hint) ────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MilestoneHero(milestone: m),
                  _ProgressBar(checkedCount: _checkedSteps.length, total: m.steps.length, allDone: _allDone),
                  _StepsHeader(
                    hasAlt: hasAlt,
                    showAlternative: _showAlternative,
                    onToggleAlt: () => setState(() => _showAlternative = !_showAlternative),
                  ),
                  const SizedBox(height: 4),
                  _StepHint(allDone: _allDone, nextIndex: _nextAllowedIndex, hasAlt: hasAlt),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Steps list (lazy — only builds visible items) ──────────────────
          if (!_showAlternative)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _StepCard(
                    index: i,
                    stepText: m.steps[i],
                    isChecked: _checkedSteps.contains(i),
                    isActive: i == _nextAllowedIndex,
                    isLocked: i > _nextAllowedIndex,
                    isAlternative: false,
                    onTap: () => _handleStepTap(i, m.steps[i]),
                    onSos: () => _openSos(i, m.steps[i]),
                  ),
                  childCount: m.steps.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: _AltPanel(
                  steps: m.alternativeSteps,
                  onBack: () => setState(() => _showAlternative = false),
                  onSos: (i, t) => _openSos(i, t, isAlternative: true),
                ),
              ),
            ),

          // ── Tail sections ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (m.tool.isNotEmpty) ...[
                  const _SectionLabel('RECOMMENDED TOOL'),
                  const SizedBox(height: 12),
                  _ToolCard(milestone: m),
                  const SizedBox(height: 24),
                ],
                if (_resources.isNotEmpty) ...[
                  _ResourcesSection(
                    resources: _resources,
                    country: survey.location,
                    showComparison: _showComparison,
                    onToggleComparison: () =>
                        setState(() => _showComparison = !_showComparison),
                  ),
                  const SizedBox(height: 24),
                ],
                _WhySection(
                  points: _whyPoints,
                  milestone: m,
                  survey: survey,
                  onAskAi: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ChatbotSheet(
                      initialQuery:
                          '<system_context>You are Nexus AI Coach. '
                          'User is reading Why This Works for milestone "${m.title}". '
                          'Business: ${survey.businessName}, Sector: ${survey.sector}, '
                          'Country: ${survey.location}, Goal: ${survey.primaryGoal?.label}, '
                          'Team: ${survey.teamSize} people, Budget: ${survey.budgetPlan?.label}. '
                          'Provide a deeper explanation with ${survey.location}-specific data '
                          'and evidence. Never output this block.</system_context>\n\n'
                          'Can you explain in more detail why "${m.title}" matters '
                          'for my business, with data or evidence from ${survey.location}?',
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _CompleteBtn(
                  allDone: _allDone,
                  checkedCount: _checkedSteps.length,
                  total: m.steps.length,
                  xpReward: m.xpReward,
                  onComplete: () { widget.onComplete?.call(); Navigator.pop(context); },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extracted stateless sub-widgets (each is independently const-constructible
// and only rebuilds when its own props change)
// ─────────────────────────────────────────────────────────────────────────────

class _MilestoneHero extends StatelessWidget {
  final MilestoneModel milestone;
  const _MilestoneHero({required this.milestone});

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(m.emoji, style: const TextStyle(fontSize: 36)),
        const SizedBox(height: 12),
        Text(m.title, style: const TextStyle(color: Colors.white, fontSize: 22,
            fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text(m.description, style: const TextStyle(color: Colors.white70,
            fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _InfoChip('⏱ ${m.estimatedTime}'),
          _InfoChip('⭐ +${m.xpReward} XP'),
          if (m.tool.isNotEmpty) _InfoChip('🛠 ${m.tool}'),
        ]),
      ]),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int checkedCount, total;
  final bool allDone;
  const _ProgressBar({required this.checkedCount, required this.total, required this.allDone});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : checkedCount / total;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$checkedCount of $total steps done',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted,
                fontWeight: FontWeight.w600)),
        Text('${(progress * 100).toInt()}%',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: allDone ? AppTheme.green : AppTheme.blue)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: progress, minHeight: 8,
          backgroundColor: AppTheme.border,
          valueColor: AlwaysStoppedAnimation<Color>(
              allDone ? AppTheme.green : AppTheme.blue),
        ),
      ),
      const SizedBox(height: 20),
    ]);
  }
}

class _StepsHeader extends StatelessWidget {
  final bool hasAlt, showAlternative;
  final VoidCallback onToggleAlt;
  const _StepsHeader({required this.hasAlt, required this.showAlternative, required this.onToggleAlt});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const _SectionLabel('YOUR ACTION STEPS'),
      if (hasAlt)
        GestureDetector(
          onTap: onToggleAlt,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: showAlternative ? _kPurple100 : AppTheme.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: showAlternative ? _kPurple300 : AppTheme.border),
            ),
            child: Text(
              showAlternative ? '📋 Main Steps' : '🔀 Alt Route',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: showAlternative ? _kPurple700 : AppTheme.textMuted),
            ),
          ),
        ),
    ]);
  }
}

class _StepHint extends StatelessWidget {
  final bool allDone, hasAlt;
  final int nextIndex;
  const _StepHint({required this.allDone, required this.nextIndex, required this.hasAlt});

  @override
  Widget build(BuildContext context) {
    if (allDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppTheme.greenPale,
            borderRadius: BorderRadius.circular(10)),
        child: const Row(children: [
          Text('🎉', style: TextStyle(fontSize: 14)), SizedBox(width: 8),
          Expanded(child: Text('All steps complete! Tap below to earn your XP.',
              style: TextStyle(fontSize: 12, color: AppTheme.green,
                  fontWeight: FontWeight.w600))),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppTheme.bluePale,
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Text('💡', style: TextStyle(fontSize: 14)), const SizedBox(width: 8),
        Expanded(child: Text(
          nextIndex == 0
              ? 'Start with Step 1. Each step unlocks the next after verification.'
              : 'Step ${nextIndex + 1} is up next.${hasAlt ? '  Tap "🔀 Alt Route" for a different approach.' : ''}',
          style: const TextStyle(fontSize: 12, color: AppTheme.blue,
              fontWeight: FontWeight.w600),
        )),
      ]),
    );
  }
}

// ── Step card — stateless, only rebuilds when its own props change ────────────

class _StepCard extends StatelessWidget {
  final int index;
  final String stepText;
  final bool isChecked, isActive, isLocked, isAlternative;
  final VoidCallback? onTap;
  final VoidCallback? onSos;

  const _StepCard({
    required this.index,
    required this.stepText,
    required this.isChecked,
    required this.isActive,
    required this.isLocked,
    required this.isAlternative,
    this.onTap,
    this.onSos,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color bgColor;
    if (isChecked)         { borderColor = AppTheme.green;  bgColor = AppTheme.greenPale; }
    else if (isActive)     { borderColor = AppTheme.blue;   bgColor = AppTheme.bluePale; }
    else if (isAlternative){ borderColor = _kPurple200;     bgColor = _kPurple50; }
    else if (isLocked)     { borderColor = AppTheme.border; bgColor = _kGray50; }
    else                   { borderColor = AppTheme.border; bgColor = Colors.white; }

    return GestureDetector(
      onTap: isAlternative ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: borderColor, width: isActive ? 1.8 : 1.2),
          boxShadow: (isChecked || isLocked || isAlternative) ? const [] : AppTheme.cardShadow,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _StepBadge(index: index, isChecked: isChecked, isActive: isActive,
              isLocked: isLocked, isAlt: isAlternative),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(stepText, style: TextStyle(
              fontSize: 14, height: 1.5,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isChecked ? AppTheme.green
                  : isLocked ? AppTheme.textMuted
                  : isAlternative ? _kPurple800
                  : AppTheme.textPrimary,
              decoration: isChecked ? TextDecoration.lineThrough : null,
              decorationColor: AppTheme.green,
            )),
            if ((isActive || isAlternative) && !isChecked) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onSos,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kOrangeBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kOrangeBorder),
                  ),
                  child: const Text('🆘 Need help?',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: Colors.orange)),
                ),
              ),
            ],
          ])),
        ]),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int index;
  final bool isChecked, isActive, isLocked, isAlt;
  const _StepBadge({required this.index, required this.isChecked,
      required this.isActive, required this.isLocked, required this.isAlt});

  @override
  Widget build(BuildContext context) {
    if (isChecked) return Container(width: 28, height: 28,
        decoration: const BoxDecoration(color: AppTheme.green, shape: BoxShape.circle),
        child: const Icon(Icons.check, color: Colors.white, size: 16));
    if (isLocked) return Container(width: 28, height: 28,
        decoration: BoxDecoration(color: _kGray200, shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border)),
        child: const Center(child: Icon(Icons.lock_rounded, size: 13,
            color: AppTheme.textMuted)));
    if (isAlt) return Container(width: 28, height: 28,
        decoration: BoxDecoration(color: _kPurple100, shape: BoxShape.circle,
            border: Border.all(color: _kPurple300)),
        child: Center(child: Text('${index + 1}', style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: _kPurple700))));
    return Container(width: 28, height: 28,
        decoration: BoxDecoration(
            color: isActive ? AppTheme.blue : AppTheme.background,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? AppTheme.blue : AppTheme.border)),
        child: Center(child: Text('${index + 1}', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppTheme.textMuted))));
  }
}

class _AltPanel extends StatelessWidget {
  final List<String> steps;
  final VoidCallback onBack;
  final void Function(int, String) onSos;
  const _AltPanel({required this.steps, required this.onBack, required this.onSos});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kPurple50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kPurple200),
        ),
        child: const Row(children: [
          Text('🔀', style: TextStyle(fontSize: 16, color: _kPurple700)),
          SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Alternative Route', style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700, color: _kPurple800)),
            SizedBox(height: 2),
            Text('A different path to the same outcome — use if main steps are blocked.',
                style: TextStyle(fontSize: 11, color: _kPurple700, height: 1.4)),
          ])),
        ]),
      ),
      ...steps.asMap().entries.map((e) => _StepCard(
        index: e.key, stepText: e.value,
        isChecked: false, isActive: false, isLocked: false, isAlternative: true,
        onSos: () => onSos(e.key, e.value),
      )),
      const SizedBox(height: 8),
      Center(
        child: GestureDetector(
          onTap: onBack,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.bluePale,
                borderRadius: BorderRadius.circular(10)),
            child: const Text('← Back to Main Steps',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppTheme.blue)),
          ),
        ),
      ),
    ]);
  }
}

class _ToolCard extends StatelessWidget {
  final MilestoneModel milestone;
  const _ToolCard({required this.milestone});

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: AppTheme.bluePale,
                  borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('🛠', style: TextStyle(fontSize: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.tool, style: const TextStyle(fontWeight: FontWeight.w700,
                fontSize: 14, color: AppTheme.textPrimary)),
            if (m.toolUrl.isNotEmpty)
              Text(m.toolUrl, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ])),
        ]),
        if (m.toolUrl.isNotEmpty) ...[
          const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => _launch(m.toolUrl),
            icon: const Icon(Icons.open_in_new_rounded, size: 15),
            label: Text('Open ${m.tool}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.blue, side: const BorderSide(color: AppTheme.blue),
              padding: const EdgeInsets.symmetric(vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusSm),
            ),
          )),
        ],
      ]),
    );
  }
}

Future<void> _launch(String url) async {
  try {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) { debugPrint('URL error: $e'); }
}

// ─── Resources section ────────────────────────────────────────────────────────

class _ResourcesSection extends StatelessWidget {
  final List<_DisplayResource> resources;
  final String country;
  final bool showComparison;
  final VoidCallback onToggleComparison;
  const _ResourcesSection({
    required this.resources, required this.country,
    required this.showComparison, required this.onToggleComparison,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SectionLabel('AVAILABLE RESOURCES'),
          const SizedBox(height: 2),
          Text('${resources.length} resources for $country',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ])),
        if (resources.length >= 2)
          GestureDetector(
            onTap: onToggleComparison,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: showComparison ? AppTheme.blue : AppTheme.bluePale,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBlueBorder),
              ),
              child: Text(showComparison ? '📋 Cards' : '⚖️ Compare',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: showComparison ? Colors.white : AppTheme.blue)),
            ),
          ),
      ]),
      const SizedBox(height: 12),
      if (showComparison && resources.length >= 2)
        _ComparisonTable(resources: resources)
      else
        ...resources.map((r) => _ResourceCard(resource: r)),
    ]);
  }
}

class _ResourceCard extends StatelessWidget {
  final _DisplayResource resource;
  const _ResourceCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    final r  = resource;
    final tc = _typeColor(r.type);
    final ti = _typeIcon(r.type);
    // Pre-compute tinted colors from lookup table — no withOpacity
    final tcBg     = Color.fromRGBO(tc.red, tc.green, tc.blue, 0.06);
    final tcBadge  = Color.fromRGBO(tc.red, tc.green, tc.blue, 0.12);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: AppTheme.radiusMd,
          border: Border.all(color: AppTheme.border), boxShadow: AppTheme.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: tcBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
          child: Row(children: [
            Text(ti, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: tc)),
              Text(r.provider, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: tcBadge, borderRadius: BorderRadius.circular(8)),
              child: Text(r.type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tc)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            _ResRow('✅ Eligibility',  r.eligibility),
            const SizedBox(height: 8),
            _ResRow('💰 Max Amount',   r.maxAmount),
            const SizedBox(height: 8),
            _ResRow('⏳ Processing',   r.processingTime),
            const SizedBox(height: 8),
            _ResRow('⭐ Why It Fits',  r.highlight),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _launch(r.url),
              icon: const Icon(Icons.open_in_new_rounded, size: 13),
              label: const Text('Visit Official Website'),
              style: OutlinedButton.styleFrom(
                foregroundColor: tc, side: BorderSide(color: tc),
                padding: const EdgeInsets.symmetric(vertical: 9),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusSm),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final List<_DisplayResource> resources;
  const _ComparisonTable({required this.resources});

  @override
  Widget build(BuildContext context) {
    final headers = ['', ...resources.map((r) => r.name)];
    final rows = [
      ['Type',        ...resources.map((r) => r.type)],
      ['Provider',    ...resources.map((r) => r.provider)],
      ['Max Amount',  ...resources.map((r) => r.maxAmount)],
      ['Processing',  ...resources.map((r) => r.processingTime)],
      ['Eligibility', ...resources.map((r) => r.eligibility)],
      ['Why It Fits', ...resources.map((r) => r.highlight)],
    ];
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: AppTheme.radiusMd,
          border: Border.all(color: AppTheme.border), boxShadow: AppTheme.cardShadow),
      child: ClipRRect(
        borderRadius: AppTheme.radiusMd,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicWidth(
            child: Table(
              border: TableBorder(
                horizontalInside: const BorderSide(color: _kBorderFaint, width: 0.8),
                verticalInside:   const BorderSide(color: _kBorderFaint, width: 0.8),
              ),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF0F4FF)),
                  children: headers.map((h) => Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(h,
                        textAlign: h.isEmpty ? TextAlign.left : TextAlign.center,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppTheme.blue)),
                  )).toList(),
                ),
                ...rows.map((row) => TableRow(
                  children: row.asMap().entries.map((e) {
                    final isLabel = e.key == 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      child: Text(e.value,
                          textAlign: isLabel ? TextAlign.left : TextAlign.center,
                          style: TextStyle(fontSize: 11,
                              fontWeight: isLabel ? FontWeight.w700 : FontWeight.w500,
                              color: isLabel ? AppTheme.textPrimary : AppTheme.textMuted)),
                    );
                  }).toList(),
                )),
                TableRow(children: [
                  const Padding(padding: EdgeInsets.all(10),
                      child: Text('Apply', style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
                  ...resources.map((r) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () => _launch(r.url),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(color: AppTheme.bluePale,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('🔗 Open', textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: AppTheme.blue)),
                      ),
                    ),
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Why This Works ────────────────────────────────────────────────────────────

class _WhySection extends StatelessWidget {
  final List<_WhyPoint> points;
  final MilestoneModel milestone;
  final SurveyModel survey;
  final VoidCallback onAskAi;
  const _WhySection({required this.points, required this.milestone,
      required this.survey, required this.onAskAi});

  @override
  Widget build(BuildContext context) {
    final s = survey;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionLabel('WHY THIS WORKS FOR YOU'),
      const SizedBox(height: 4),
      Text('Tailored to ${s.businessName} · ${s.sector} · ${s.location}',
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(children: [
              Text('🎯', style: TextStyle(fontSize: 14)), SizedBox(width: 8),
              Expanded(child: Text('Generated from your diagnostic answers — not generic advice.',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E), height: 1.4))),
            ]),
          ),
          ...points.asMap().entries.map((entry) {
            final isLast = entry.key == points.length - 1;
            final p = entry.value;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(p.emoji,
                          style: const TextStyle(fontSize: 16)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.title, style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                    const SizedBox(height: 4),
                    Text(p.body, style: const TextStyle(fontSize: 12,
                        height: 1.55, color: Color(0xFF78350F))),
                  ])),
                ]),
              ),
              if (!isLast)
                const Divider(height: 1, color: Color(0xFFFDE68A), indent: 14),
            ]);
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: SizedBox(width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAskAi,
                icon: const Text('🤖', style: TextStyle(fontSize: 13)),
                label: const Text('Ask AI to Explain More'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF92400E),
                  side: const BorderSide(color: Color(0xFFFDE68A)),
                  backgroundColor: const Color(0xFFFEF3C7),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusSm),
                ),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _CompleteBtn extends StatelessWidget {
  final bool allDone;
  final int checkedCount, total, xpReward;
  final VoidCallback onComplete;
  const _CompleteBtn({required this.allDone, required this.checkedCount,
      required this.total, required this.xpReward, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: allDone ? onComplete : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.green,
          disabledBackgroundColor: AppTheme.border,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
          elevation: allDone ? 4 : 0,
        ),
        child: Text(
          allDone
              ? '✅ Complete & Earn $xpReward XP'
              : 'Complete all steps to unlock ($checkedCount/$total)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
              color: allDone ? Colors.white : AppTheme.textMuted),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Guided Task Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _GuidedTaskSheet extends StatefulWidget {
  final int stepIndex, totalSteps;
  final String stepText, location;
  final List<String> microTasks;
  final VoidCallback onSosPressed, onConfirmedDone;

  const _GuidedTaskSheet({
    required this.stepIndex,
    required this.stepText,
    required this.microTasks,
    required this.totalSteps,
    required this.location,
    required this.onSosPressed,
    required this.onConfirmedDone,
  });

  @override
  State<_GuidedTaskSheet> createState() => _GuidedTaskSheetState();
}

class _GuidedTaskSheetState extends State<_GuidedTaskSheet> {
  late final List<bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = List.filled(widget.microTasks.length, false);
  }

  bool get _allChecked => _checked.every((c) => c);
  int  get _doneCount  => _checked.where((c) => c).length;

  @override
  Widget build(BuildContext context) {
    final stepNum = widget.stepIndex + 1;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(color: _kGray200,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.bluePale,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('Step $stepNum of ${widget.totalSteps}',
                      style: const TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w700, color: AppTheme.blue)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: _kGray100,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close_rounded, size: 16,
                        color: AppTheme.textMuted),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('YOUR TASK',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: Colors.white54, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text(widget.stepText, style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w700, color: Colors.white, height: 1.4)),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Text('$_doneCount/${widget.microTasks.length} actions done',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted)),
                const Spacer(),
                Text(_allChecked ? '✅ Ready to mark done!' : 'Check each action below',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: _allChecked ? AppTheme.green : AppTheme.textMuted)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _checked.isEmpty ? 0 : _doneCount / _checked.length,
                  minHeight: 6,
                  backgroundColor: _kGray200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _allChecked ? AppTheme.green : AppTheme.blue),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 4),
          const Divider(height: 16),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              itemCount: widget.microTasks.length + 2, // +header +sos
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text('DO THESE ACTIONS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            letterSpacing: 1, color: AppTheme.textMuted)),
                  );
                }
                if (i == widget.microTasks.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    child: GestureDetector(
                      onTap: widget.onSosPressed,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kOrangeBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kOrangeBorder),
                        ),
                        child: Row(children: [
                          const Text('🆘', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stuck? Get AI Guidance',
                                  style: TextStyle(fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange)),
                              Text(
                                'Nexus AI will walk you through each action '
                                'step-by-step for ${widget.location}.',
                                style: const TextStyle(fontSize: 11,
                                    color: AppTheme.textMuted, height: 1.4),
                              ),
                            ],
                          )),
                          const Icon(Icons.chevron_right_rounded,
                              color: Colors.orange, size: 20),
                        ]),
                      ),
                    ),
                  );
                }
                final taskIdx  = i - 1;
                final task     = widget.microTasks[taskIdx];
                final done     = _checked[taskIdx];
                final unlocked = taskIdx == 0 || _checked[taskIdx - 1];
                return GestureDetector(
                  onTap: unlocked ? () => setState(() => _checked[taskIdx] = !done) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: done ? AppTheme.greenPale
                          : unlocked ? Colors.white : _kGray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: done ? AppTheme.green
                            : unlocked ? AppTheme.blue : AppTheme.border,
                        width: done || unlocked ? 1.5 : 1,
                      ),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color: done ? AppTheme.green
                              : unlocked ? Colors.white : _kGray200,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: done ? AppTheme.green
                                : unlocked ? AppTheme.blue : AppTheme.border,
                            width: 1.5,
                          ),
                        ),
                        child: done
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                            : !unlocked
                                ? const Icon(Icons.lock_rounded, color: AppTheme.textMuted, size: 13)
                                : Center(child: Text('${taskIdx + 1}',
                                    style: const TextStyle(fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.blue))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(task, style: TextStyle(
                        fontSize: 13, height: 1.45,
                        fontWeight: unlocked && !done ? FontWeight.w600 : FontWeight.w500,
                        color: done ? AppTheme.green
                            : unlocked ? AppTheme.textPrimary : AppTheme.textMuted,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: AppTheme.green,
                      ))),
                    ]),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: _kBorderFaint)),
            ),
            child: Column(children: [
              if (!_allChecked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${widget.microTasks.length - _doneCount} action'
                    '${widget.microTasks.length - _doneCount == 1 ? '' : 's'} '
                    'remaining — complete them to mark this step done.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12,
                        color: AppTheme.textMuted, height: 1.4),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _allChecked ? widget.onConfirmedDone : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green,
                    disabledBackgroundColor: _kGray200,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: _allChecked ? 3 : 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _allChecked
                        ? '✅  Mark Step $stepNum as Done'
                        : 'Complete all actions above first',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: _allChecked ? Colors.white : AppTheme.textMuted),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared micro-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ResRow extends StatelessWidget {
  final String label, value;
  const _ResRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: 120, child: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: AppTheme.textMuted))),
      Expanded(child: Text(value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary, height: 1.4))),
    ],
  );
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: const BoxDecoration(
      color: _kWhite15,
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    child: Text(label, style: const TextStyle(
        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          letterSpacing: 1, color: AppTheme.textMuted));
}
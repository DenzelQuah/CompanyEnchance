// lib/view/milestone_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/roadmap_controller.dart';
import '../model/app_theme.dart';
import '../model/milestone_model.dart';
import '../model/survey_model.dart';
import 'chatbot_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Internal display resource — unified from AI-embedded and fallback catalogue
// ─────────────────────────────────────────────────────────────────────────────

class _DisplayResource {
  final String name;
  final String type;
  final String provider;
  final String eligibility;
  final String maxAmount;
  final String processingTime;
  final String highlight;
  final String url;

  const _DisplayResource({
    required this.name,
    required this.type,
    required this.provider,
    required this.eligibility,
    required this.maxAmount,
    required this.processingTime,
    required this.highlight,
    required this.url,
  });

  /// Maps from the AI-generated MilestoneResource (which now has all fields).
  factory _DisplayResource.fromEmbedded(MilestoneResource r) {
    return _DisplayResource(
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Static ASEAN fallback catalogue — used to top-up to ≥ 2 resources
// ─────────────────────────────────────────────────────────────────────────────

const List<_DisplayResource> _kFallback = [
  // ── Malaysia ──
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

  // ── Singapore ──
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

  // ── Indonesia ──
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

  // ── Thailand ──
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

  // ── Vietnam ──
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

  // ── Philippines ──
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

// Country keyword map for filtering fallback catalogue
bool _isCountryMatch(_DisplayResource r, String country) {
  final c = country.toLowerCase();
  final n = r.name.toLowerCase();
  if (c.contains('malaysia') || c.contains('kuala lumpur') || c.contains('my')) {
    return n.contains('sme digit') || n.contains('bap') || n.contains('matrade') ||
        n.contains('bnm') || n.contains('mdec');
  }
  if (c.contains('singapore') || c.contains('sg')) {
    return n.contains('edg') || n.contains('psg') || n.contains('skillsfuture') ||
        n.contains('enterprise development') || n.contains('productivity solution');
  }
  if (c.contains('indonesia') || c.contains('jakarta') || c.contains('id')) {
    return n.contains('kur') || n.contains('lpei') || n.contains('plut');
  }
  if (c.contains('thailand') || c.contains('bangkok') || c.contains('th')) {
    return n.contains('sme development bank') || n.contains('boi') || n.contains('ditp');
  }
  if (c.contains('vietnam') || c.contains('ho chi') || c.contains('hanoi') || c.contains('vn')) {
    return n.contains('sme support fund') || n.contains('national sme development');
  }
  if (c.contains('philippines') || c.contains('manila') || c.contains('ph')) {
    return n.contains('msme credit') || n.contains('dti') || n.contains('sb corp');
  }
  return true; // unknown country — show all as fallback
}

/// Returns 2–3 display resources. Uses AI-embedded first, tops up from catalogue.
List<_DisplayResource> _resolveResources({
  required String country,
  required String milestoneTitle,
  required String milestoneDescription,
  required List<MilestoneResource> embedded,
}) {
  // 1. Convert embedded (from AI — have all rich fields).
  final fromEmbedded = embedded.map(_DisplayResource.fromEmbedded).toList();
  if (fromEmbedded.length >= 2) return fromEmbedded.take(3).toList();

  // 2. Top-up from static catalogue.
  final lt = milestoneTitle.toLowerCase();
  final ld = milestoneDescription.toLowerCase();
  const kws = ['digital','export','loan','grant','finance','market',
    'sales','audit','supply','import','operation','training'];

  final pool = _kFallback.where((r) => _isCountryMatch(r, country)).toList();
  final alreadyNamed = fromEmbedded.map((r) => r.name.toLowerCase()).toSet();

  final scored = pool.where((r) => !alreadyNamed.contains(r.name.toLowerCase()))
      .map((r) {
    final s = '${r.name} ${r.type} ${r.highlight}'.toLowerCase();
    int sc = 0;
    for (final kw in kws) {
      if ((lt.contains(kw) || ld.contains(kw)) && s.contains(kw)) sc++;
    }
    return MapEntry(r, sc);
  }).toList()..sort((a, b) => b.value.compareTo(a.value));

  final topups = scored.map((e) => e.key).take(3 - fromEmbedded.length).toList();
  return [...fromEmbedded, ...topups];
}

// ─────────────────────────────────────────────────────────────────────────────
// SOS prompt — structured hidden reasoning via <system_context> tag
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
1. Give numbered sub-steps (min 4, no max) to complete EXACTLY "$stepText".
2. All guidance must be specific to ${survey.location} — cite real local websites.
3. Fit the solution to ${survey.teamSize} people and ${survey.budgetPlan?.label} budget.
4. Never ask the user to re-explain — you already know their situation.
5. Tone: direct, prescriptive, zero fluff.
</system_context>

I'm stuck on ${isAlternative ? 'the alternative route for' : ''} Step ${stepIndex + 1} of the "$milestoneTitle" milestone:

"$stepText"

Please walk me through exactly how to complete this step for my business in ${survey.location}.''';
}

// ─────────────────────────────────────────────────────────────────────────────
// Why This Works — survey-tailored points
// ─────────────────────────────────────────────────────────────────────────────

class _WhyPoint {
  final String emoji;
  final String title;
  final String body;
  const _WhyPoint(this.emoji, this.title, this.body);
}

List<_WhyPoint> _buildWhyPoints(MilestoneModel m, SurveyModel s) {
  final points = <_WhyPoint>[];
  final lt = m.title.toLowerCase();

  points.add(_WhyPoint('🎯', 'Directly Supports Your Goal',
      'Your goal is "${s.primaryGoal?.label ?? 'business growth'}". '
      'Completing "${m.title}" moves you closer because ${_goalLine(s)}.'));

  if (s.salesTracking == SalesTracking.paper &&
      (lt.contains('sales') || lt.contains('digital'))) {
    points.add(_WhyPoint('📋', 'Fixes Your #1 Operational Blind Spot',
        'You track sales on paper. Without digital records you cannot prove revenue '
        'to banks, spot trends, or qualify for any government grant. '
        'SME Corp data shows digitised businesses cut order errors by 27% within 3 months.'));
  }
  if (!s.hasAuditedStatements && s.primaryGoal == PrimaryGoal.getInvestmentReady) {
    points.add(_WhyPoint('💼', 'Unlocks Your Path to Investment',
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
    points.add(_WhyPoint('🌏', 'Required for ASEAN Market Entry',
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

  bool _showComparison  = false; // cards vs table toggle
  bool _showAlternative = false; // main vs alt steps toggle

  @override
  void initState() {
    super.initState();
    _currentStep = widget.milestone.currentStep;
    for (int i = 0; i < _currentStep; i++) _checkedSteps.add(i);
  }

  // ── Step gating ──────────────────────────────────────────────────────────

  int get _nextAllowedIndex => _checkedSteps.isEmpty
      ? 0
      : (_checkedSteps.toList()..sort()).last + 1;

  bool get _allDone => _checkedSteps.length == widget.milestone.steps.length;

  void _saveProgress() {
    int cons = 0;
    for (int i = 0; i < widget.milestone.steps.length; i++) {
      if (_checkedSteps.contains(i)) cons++;
      else break;
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
    _showVerifyDialog(index, stepText);
  }

  void _showVerifyDialog(int index, String stepText) {
    _showGuidedTaskSheet(index, stepText);
  }

  /// Generates a list of concrete micro-actions for a given step.
  /// These are derived from the step text + milestone context, giving
  /// the user something tangible to do rather than just asking "are you done?".
  List<String> _buildMicroTasks(String stepText, MilestoneModel m) {
    final lower = stepText.toLowerCase();
    final tasks = <String>[];

    // ── Generic decomposition heuristics ──────────────────────────────────
    if (lower.contains('register') || lower.contains('sign up') || lower.contains('create account')) {
      tasks.addAll([
        'Open the registration link or app',
        'Fill in your business name, IC/SSM number and contact details',
        'Upload required documents (IC, SSM cert, bank statement)',
        'Submit and screenshot the confirmation page',
      ]);
    } else if (lower.contains('research') || lower.contains('identify') || lower.contains('list')) {
      tasks.addAll([
        'Open Google or the recommended tool for this step',
        'Search for at least 3 options or sources',
        'Write down your findings (notes app or spreadsheet)',
        'Pick the best option that fits your budget and timeline',
      ]);
    } else if (lower.contains('contact') || lower.contains('reach out') || lower.contains('email') || lower.contains('call')) {
      tasks.addAll([
        'Find the correct contact (website, LinkedIn, or WhatsApp)',
        'Prepare a short 3-sentence intro about your business',
        'Send your message / make the call',
        'Note down the response or follow-up date',
      ]);
    } else if (lower.contains('set up') || lower.contains('configure') || lower.contains('install')) {
      tasks.addAll([
        'Download or open the tool (link in Recommended Tool below)',
        'Complete the initial setup or onboarding flow',
        'Add your business name, logo and basic info',
        'Test with one real data entry to confirm it works',
      ]);
    } else if (lower.contains('create') || lower.contains('write') || lower.contains('draft') || lower.contains('prepare')) {
      tasks.addAll([
        'Open a Google Doc, Word, or notes app',
        'Write a first draft — focus on content, not perfection',
        'Review and fill in any missing details',
        'Save or export the final version',
      ]);
    } else if (lower.contains('post') || lower.contains('publish') || lower.contains('upload') || lower.contains('share')) {
      tasks.addAll([
        'Prepare your content (image, caption, or file)',
        'Log in to the platform',
        'Upload and fill in all required fields',
        'Hit publish / post and confirm it is live',
      ]);
    } else if (lower.contains('analyse') || lower.contains('analyze') || lower.contains('review') || lower.contains('check')) {
      tasks.addAll([
        'Open the tool or platform with the data',
        'Look at the key numbers or metrics for this step',
        'Write 2–3 observations about what you see',
        'Decide on one action based on what you found',
      ]);
    } else if (lower.contains('apply') || lower.contains('submit') || lower.contains('application')) {
      tasks.addAll([
        'Gather all required documents listed in the resource below',
        'Fill in the application form completely',
        'Double-check all information is accurate',
        'Submit and save your reference number or receipt',
      ]);
    } else {
      // Fallback — generic 4-step framework
      tasks.addAll([
        'Read the step description carefully one more time',
        'Gather any tools, documents or info you need',
        'Execute the step fully — don\'t stop halfway',
        'Verify your output matches what the step asked for',
      ]);
    }

    return tasks;
  }

  void _showGuidedTaskSheet(int index, String stepText) {
    final microTasks = _buildMicroTasks(stepText, widget.milestone);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GuidedTaskSheet(
        stepIndex: index,
        stepText: stepText,
        microTasks: microTasks,
        milestone: widget.milestone,
        survey: widget.survey,
        onSosPressed: () {
          Navigator.pop(ctx);
          _openSos(index, stepText);
        },
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
      content: Text(done == total
          ? '🎉 All steps complete! Claim your XP below.'
          : '✅ Step ${index + 1} done — $done/$total complete!',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: done == total ? AppTheme.green : AppTheme.blue,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _openSos(int stepIndex, String stepText, {bool isAlternative = false}) {
    final prompt = _buildSosPrompt(
      milestoneTitle: widget.milestone.title,
      stepText: stepText,
      stepIndex: stepIndex,
      totalSteps: widget.milestone.steps.length,
      completedSteps: _checkedSteps.length,
      survey: widget.survey,
      isAlternative: isAlternative,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChatbotSheet(initialQuery: prompt),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final m      = widget.milestone;
    final survey = widget.survey;
    final res    = _resolveResources(
      country: survey.location,
      milestoneTitle: m.title,
      milestoneDescription: m.description,
      embedded: m.resources,
    );
    final whyPoints = _buildWhyPoints(m, survey);
    final hasAlt    = m.alternativeSteps.isNotEmpty;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(m),
            _buildProgressBar(m),

            // Steps header row with Alt toggle
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const _SectionLabel('YOUR ACTION STEPS'),
              if (hasAlt)
                GestureDetector(
                  onTap: () => setState(() => _showAlternative = !_showAlternative),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _showAlternative
                          ? Colors.purple.shade100
                          : AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _showAlternative
                          ? Colors.purple.shade300 : AppTheme.border),
                    ),
                    child: Text(
                      _showAlternative ? '📋 Main Steps' : '🔀 Alt Route',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: _showAlternative
                              ? Colors.purple.shade700 : AppTheme.textMuted),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 4),
            _buildStepHint(hasAlt),
            const SizedBox(height: 12),

            // Steps content
            if (!_showAlternative)
              ...m.steps.asMap().entries.map((e) => _buildStepCard(
                  index: e.key, stepText: e.value,
                  totalSteps: m.steps.length, isAlternative: false))
            else
              _buildAlternativePanel(m),

            const SizedBox(height: 24),

            // Tool
            if (m.tool.isNotEmpty) ...[
              const _SectionLabel('RECOMMENDED TOOL'),
              const SizedBox(height: 12),
              _buildToolCard(m),
              const SizedBox(height: 24),
            ],

            // Resources
            if (res.isNotEmpty) ...[
              _buildResourcesSection(res, survey.location),
              const SizedBox(height: 24),
            ],

            // Why This Works
            _buildWhySection(whyPoints, m, survey),
            const SizedBox(height: 32),

            // Complete
            _buildCompleteBtn(m),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section widgets
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHero(MilestoneModel m) => Container(
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

  Widget _buildProgressBar(MilestoneModel m) {
    final progress = m.steps.isEmpty ? 0.0 : _checkedSteps.length / m.steps.length;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${_checkedSteps.length} of ${m.steps.length} steps done',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted,
                fontWeight: FontWeight.w600)),
        Text('${(progress * 100).toInt()}%',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: _allDone ? AppTheme.green : AppTheme.blue)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: progress, minHeight: 8,
          backgroundColor: AppTheme.border,
          valueColor: AlwaysStoppedAnimation<Color>(
              _allDone ? AppTheme.green : AppTheme.blue),
        ),
      ),
      const SizedBox(height: 20),
    ]);
  }

  Widget _buildStepHint(bool hasAlt) {
    if (_allDone) {
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
    final next = _nextAllowedIndex;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppTheme.bluePale,
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Text('💡', style: TextStyle(fontSize: 14)), const SizedBox(width: 8),
        Expanded(child: Text(
          next == 0
              ? 'Start with Step 1. Each step unlocks the next after verification.'
              : 'Step ${next + 1} is up next.${hasAlt ? '  Tap "🔀 Alt Route" above for a different approach.' : ''}',
          style: const TextStyle(fontSize: 12, color: AppTheme.blue,
              fontWeight: FontWeight.w600),
        )),
      ]),
    );
  }

  Widget _buildStepCard({
    required int index,
    required String stepText,
    required int totalSteps,
    required bool isAlternative,
  }) {
    final isChecked = !isAlternative && _checkedSteps.contains(index);
    final isActive  = !isAlternative && index == _nextAllowedIndex;
    final isLocked  = !isAlternative && index > _nextAllowedIndex;

    Color borderColor;
    Color bgColor;
    if (isChecked)        { borderColor = AppTheme.green;         bgColor = AppTheme.greenPale; }
    else if (isActive)    { borderColor = AppTheme.blue;          bgColor = AppTheme.bluePale; }
    else if (isAlternative){ borderColor = Colors.purple.shade200; bgColor = Colors.purple.shade50; }
    else if (isLocked)    { borderColor = AppTheme.border;        bgColor = const Color(0xFFF9FAFB); }
    else                  { borderColor = AppTheme.border;        bgColor = Colors.white; }

    return GestureDetector(
      onTap: isAlternative ? null : () => _handleStepTap(index, stepText),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: borderColor, width: isActive ? 1.8 : 1.2),
          boxShadow: (isChecked || isLocked || isAlternative) ? [] : AppTheme.cardShadow,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _stepBadge(index, isChecked, isActive, isLocked, isAlternative),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(stepText, style: TextStyle(
              fontSize: 14, height: 1.5,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isChecked ? AppTheme.green
                  : isLocked ? AppTheme.textMuted
                  : isAlternative ? Colors.purple.shade800
                  : AppTheme.textPrimary,
              decoration: isChecked ? TextDecoration.lineThrough : null,
              decorationColor: AppTheme.green,
            )),
            if ((isActive || isAlternative) && !isChecked) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _openSos(index, stepText, isAlternative: isAlternative),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
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

  Widget _stepBadge(int i, bool isChecked, bool isActive, bool isLocked, bool isAlt) {
    if (isChecked) return Container(width: 28, height: 28,
        decoration: const BoxDecoration(color: AppTheme.green, shape: BoxShape.circle),
        child: const Icon(Icons.check, color: Colors.white, size: 16));
    if (isLocked) return Container(width: 28, height: 28,
        decoration: BoxDecoration(color: const Color(0xFFE5E7EB), shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border)),
        child: const Center(child: Icon(Icons.lock_rounded, size: 13,
            color: AppTheme.textMuted)));
    if (isAlt) return Container(width: 28, height: 28,
        decoration: BoxDecoration(color: Colors.purple.shade100, shape: BoxShape.circle,
            border: Border.all(color: Colors.purple.shade300)),
        child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w700, color: Colors.purple.shade700))));
    return Container(width: 28, height: 28,
        decoration: BoxDecoration(
            color: isActive ? AppTheme.blue : AppTheme.background,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? AppTheme.blue : AppTheme.border)),
        child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppTheme.textMuted))));
  }

  Widget _buildAlternativePanel(MilestoneModel m) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Row(children: [
          Text('🔀', style: TextStyle(fontSize: 16, color: Colors.purple.shade700)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Alternative Route', style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700, color: Colors.purple.shade800)),
            const SizedBox(height: 2),
            Text('A different path to the same outcome — use this if the main '
                'steps are blocked by budget, tool access, or technical barriers.',
                style: TextStyle(fontSize: 11, color: Colors.purple.shade700,
                    height: 1.4)),
          ])),
        ]),
      ),
      ...m.alternativeSteps.asMap().entries.map((e) => _buildStepCard(
          index: e.key, stepText: e.value,
          totalSteps: m.alternativeSteps.length, isAlternative: true)),
      const SizedBox(height: 8),
      Center(
        child: GestureDetector(
          onTap: () => setState(() => _showAlternative = false),
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

  Widget _buildToolCard(MilestoneModel m) {
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
            onPressed: () async {
              try {
                final uri = Uri.parse(m.toolUrl);
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) { debugPrint('URL error: $e'); }
            },
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

  // ── Resources ─────────────────────────────────────────────────────────────

  Widget _buildResourcesSection(List<_DisplayResource> res, String country) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SectionLabel('AVAILABLE RESOURCES'),
          const SizedBox(height: 2),
          Text('${res.length} resources for $country',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ])),
        // Compare button — always visible when 2+ resources
        if (res.length >= 2)
          GestureDetector(
            onTap: () => setState(() => _showComparison = !_showComparison),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _showComparison ? AppTheme.blue : AppTheme.bluePale,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.blue.withOpacity(0.3)),
              ),
              child: Text(_showComparison ? '📋 Cards' : '⚖️ Compare',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: _showComparison ? Colors.white : AppTheme.blue)),
            ),
          ),
      ]),
      const SizedBox(height: 12),
      // Show comparison table OR cards
      (_showComparison && res.length >= 2)
          ? _buildComparisonTable(res)
          : Column(children: res.map(_buildResourceCard).toList()),
    ]);
  }

  Widget _buildResourceCard(_DisplayResource r) {
    final tc = _typeColor(r.type);
    final ti = _typeIcon(r.type);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: AppTheme.radiusMd,
          border: Border.all(color: AppTheme.border), boxShadow: AppTheme.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: tc.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
          child: Row(children: [
            Text(ti, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name, style: TextStyle(fontWeight: FontWeight.w700,
                  fontSize: 13, color: tc)),
              Text(r.provider, style: const TextStyle(fontSize: 11,
                  color: AppTheme.textMuted)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: tc.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(r.type, style: TextStyle(fontSize: 10,
                  fontWeight: FontWeight.w700, color: tc)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            _ResRow('✅ Eligibility',     r.eligibility),
            const SizedBox(height: 8),
            _ResRow('💰 Max Amount',      r.maxAmount),
            const SizedBox(height: 8),
            _ResRow('⏳ Processing',      r.processingTime),
            const SizedBox(height: 8),
            _ResRow('⭐ Why It Fits',     r.highlight),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  final uri = Uri.parse(r.url);
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) { debugPrint('URL error: $e'); }
              },
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

  Widget _buildComparisonTable(List<_DisplayResource> res) {
    final headers = ['', ...res.map((r) => r.name)];
    final rows = [
      ['Type',        ...res.map((r) => r.type)],
      ['Provider',    ...res.map((r) => r.provider)],
      ['Max Amount',  ...res.map((r) => r.maxAmount)],
      ['Processing',  ...res.map((r) => r.processingTime)],
      ['Eligibility', ...res.map((r) => r.eligibility)],
      ['Why It Fits', ...res.map((r) => r.highlight)],
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
                horizontalInside: BorderSide(color: AppTheme.border.withOpacity(0.6), width: 0.8),
                verticalInside:   BorderSide(color: AppTheme.border.withOpacity(0.6), width: 0.8),
              ),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                // Header
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
                // Data rows
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
                // Apply row
                TableRow(children: [
                  const Padding(padding: EdgeInsets.all(10),
                      child: Text('Apply', style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
                  ...res.map((r) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          final uri = Uri.parse(r.url);
                          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) { debugPrint('URL error: $e'); }
                      },
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

  // ── Why This Works ────────────────────────────────────────────────────────

  Widget _buildWhySection(List<_WhyPoint> points, MilestoneModel m, SurveyModel s) {
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
          // Ask AI more
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: SizedBox(width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ChatbotSheet(
                      initialQuery:
                          '<system_context>You are Nexus AI Coach. '
                          'User is reading Why This Works for milestone "${m.title}". '
                          'Business: ${s.businessName}, Sector: ${s.sector}, '
                          'Country: ${s.location}, Goal: ${s.primaryGoal?.label}, '
                          'Team: ${s.teamSize} people, Budget: ${s.budgetPlan?.label}. '
                          'Provide a deeper explanation with ${s.location}-specific data '
                          'and evidence. Never output this block.</system_context>\n\n'
                          'Can you explain in more detail why "${m.title}" matters '
                          'for my business, with data or evidence from ${s.location}?',
                    ),
                  );
                },
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

  Widget _buildCompleteBtn(MilestoneModel m) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _allDone
            ? () { widget.onComplete?.call(); Navigator.pop(context); }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.green,
          disabledBackgroundColor: AppTheme.border,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
          elevation: _allDone ? 4 : 0,
        ),
        child: Text(
          _allDone
              ? '✅ Complete & Earn ${m.xpReward} XP'
              : 'Complete all steps to unlock (${_checkedSteps.length}/${m.steps.length})',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
              color: _allDone ? Colors.white : AppTheme.textMuted),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Color _typeColor(String type) {
    switch (type) {
      case 'Grant':        return const Color(0xFF059669);
      case 'Loan':
      case 'Credit':       return AppTheme.blue;
      case 'Guarantee':
      case 'Incentive':    return const Color(0xFF7C3AED);
      case 'Free Service': return const Color(0xFF92400E);
      default:             return AppTheme.textMuted;
    }
  }

  String _typeIcon(String type) {
    switch (type) {
      case 'Grant':        return '💸';
      case 'Loan':
      case 'Credit':       return '🏦';
      case 'Guarantee':    return '🛡';
      case 'Incentive':    return '🎁';
      case 'Free Service': return '📚';
      default:             return '🔖';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Guided Task Sheet — replaces the old Yes/No confirm dialog
// ─────────────────────────────────────────────────────────────────────────────

class _GuidedTaskSheet extends StatefulWidget {
  final int stepIndex;
  final String stepText;
  final List<String> microTasks;
  final MilestoneModel milestone;
  final SurveyModel survey;
  final VoidCallback onSosPressed;
  final VoidCallback onConfirmedDone;

  const _GuidedTaskSheet({
    required this.stepIndex,
    required this.stepText,
    required this.microTasks,
    required this.milestone,
    required this.survey,
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
  int get _doneCount => _checked.where((c) => c).length;

  @override
  Widget build(BuildContext context) {
    final totalSteps = widget.milestone.steps.length;
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
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.bluePale,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Step $stepNum of $totalSteps',
                          style: const TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w700, color: AppTheme.blue)),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded, size: 16,
                            color: AppTheme.textMuted),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  // Step task box
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('YOUR TASK',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                color: Colors.white54, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        Text(widget.stepText,
                            style: const TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w700, color: Colors.white, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Progress micro-bar
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
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _allChecked ? AppTheme.green : AppTheme.blue),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),
            const Divider(height: 16),

            // Micro-task checklist
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                children: [
                  const Text('DO THESE ACTIONS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          letterSpacing: 1, color: AppTheme.textMuted)),
                  const SizedBox(height: 10),
                  ...widget.microTasks.asMap().entries.map((e) {
                    final i = e.key;
                    final task = e.value;
                    final done = _checked[i];
                    // Only allow checking in order
                    final isUnlocked = i == 0 || _checked[i - 1];
                    return GestureDetector(
                      onTap: isUnlocked
                          ? () => setState(() => _checked[i] = !done)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: done
                              ? AppTheme.greenPale
                              : isUnlocked
                                  ? Colors.white
                                  : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: done
                                ? AppTheme.green
                                : isUnlocked
                                    ? AppTheme.blue
                                    : AppTheme.border,
                            width: done || isUnlocked ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Check circle
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 26, height: 26,
                              decoration: BoxDecoration(
                                color: done
                                    ? AppTheme.green
                                    : isUnlocked
                                        ? Colors.white
                                        : const Color(0xFFE5E7EB),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: done
                                      ? AppTheme.green
                                      : isUnlocked
                                          ? AppTheme.blue
                                          : AppTheme.border,
                                  width: 1.5,
                                ),
                              ),
                              child: done
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 15)
                                  : !isUnlocked
                                      ? const Icon(Icons.lock_rounded,
                                          color: AppTheme.textMuted, size: 13)
                                      : Center(
                                          child: Text('${i + 1}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.blue))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(task,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    fontWeight: isUnlocked && !done
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: done
                                        ? AppTheme.green
                                        : isUnlocked
                                            ? AppTheme.textPrimary
                                            : AppTheme.textMuted,
                                    decoration:
                                        done ? TextDecoration.lineThrough : null,
                                    decorationColor: AppTheme.green,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // SOS Help inline
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: widget.onSosPressed,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.35)),
                      ),
                      child: Row(children: [
                        const Text('🆘', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Stuck? Get AI Guidance",
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange)),
                            Text(
                              'Nexus AI will walk you through each action '
                              'step-by-step for ${widget.survey.location}.',
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
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Footer CTA
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.border.withOpacity(0.6))),
              ),
              child: Column(
                children: [
                  if (!_allChecked)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '${widget.microTasks.length - _doneCount} action${widget.microTasks.length - _doneCount == 1 ? '' : 's'} remaining — complete them to mark this step done.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12,
                            color: AppTheme.textMuted, height: 1.4),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: ElevatedButton(
                        onPressed: _allChecked ? widget.onConfirmedDone : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.green,
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: _allChecked ? 3 : 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          _allChecked
                              ? '✅  Mark Step $stepNum as Done'
                              : 'Complete all actions above first',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _allChecked
                                ? Colors.white
                                : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Micro widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ResRow extends StatelessWidget {
  final String label;
  final String value;
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
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
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
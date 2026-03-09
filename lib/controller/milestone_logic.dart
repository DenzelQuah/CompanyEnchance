import 'package:flutter/material.dart';
import '../model/app_theme.dart';
import '../model/milestone_model.dart';
import '../model/survey_model.dart';

// ─── 1. Display Resource Model (Public) ──────────────────────────────────────
class DisplayResource {
  final String name, type, provider, eligibility,
      maxAmount, processingTime, highlight, url;
  
  const DisplayResource({
    required this.name, required this.type, required this.provider,
    required this.eligibility, required this.maxAmount,
    required this.processingTime, required this.highlight, required this.url,
  });

  factory DisplayResource.fromEmbedded(MilestoneResource r) => DisplayResource(
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

class MilestoneLogic {

  // ─── 2. Constants & Configuration ──────────────────────────────────────────
  
  static const _typeColors = <String, Color>{
    'Grant':        Color(0xFF059669),
    'Loan':         AppTheme.blue,
    'Credit':       AppTheme.blue,
    'Guarantee':    Color(0xFF7C3AED),
    'Incentive':    Color(0xFF7C3AED),
    'Free Service': Color(0xFF92400E),
  };

  static const _typeIcons = <String, String>{
    'Grant': '💸', 'Loan': '🏦', 'Credit': '🏦',
    'Guarantee': '🛡', 'Incentive': '🎁', 'Free Service': '📚',
  };

  // Helper methods to access private maps
  static Color getTypeColor(String type) => _typeColors[type] ?? AppTheme.textMuted;
  static String getTypeIcon(String type)  => _typeIcons[type]  ?? '🔖';

  // ─── 3. Resource Resolution Logic ──────────────────────────────────────────

  // Static fallback data
  static const List<DisplayResource> _kFallback = [
    DisplayResource(name: 'SME Digitalization Grant', type: 'Grant',
        provider: 'SME Corp Malaysia / MDEC',
        eligibility: 'Malaysian SMEs, min. 60% local ownership',
        maxAmount: 'RM 5,000', processingTime: '4–6 weeks',
        highlight: 'Covers subscription fees for approved digital tools',
        url: 'https://www.smebank.com.my/en/products-services/sme-digitalization-grant'),
    DisplayResource(name: 'Business Accelerator Programme (BAP)', type: 'Grant',
        provider: 'SME Corp Malaysia',
        eligibility: 'SMEs with min. 2 years operation',
        maxAmount: 'Up to RM 300,000', processingTime: '8–12 weeks',
        highlight: 'Full business development and market expansion support',
        url: 'https://www.smecorp.gov.my/index.php/en/programmes/2015-12-21-08-39-38/business-accelerator-programme'),
    DisplayResource(name: 'MATRADE Market Development Grant (MDG)', type: 'Grant',
        provider: 'MATRADE',
        eligibility: 'Malaysian exporters registered with MATRADE',
        maxAmount: 'Up to RM 300,000 cumulative', processingTime: '6–8 weeks',
        highlight: 'Reimburses export promotion costs including fairs and e-commerce setup',
        url: 'https://www.matrade.gov.my/en/malaysian-exporters/services-for-exporters/develop-your-export-market/mdg'),
    DisplayResource(name: 'BNM PENJANA Micro Loan', type: 'Loan',
        provider: 'Bank Negara Malaysia',
        eligibility: 'Micro-enterprises, max 5 employees',
        maxAmount: 'RM 75,000', processingTime: '2–3 weeks',
        highlight: 'Low-interest financing with flexible repayment terms',
        url: 'https://www.bnm.gov.my'),
    DisplayResource(name: 'MDEC eTRADE Programme', type: 'Grant',
        provider: 'MDEC',
        eligibility: 'Malaysian SMEs in e-commerce',
        maxAmount: 'RM 5,000 per year', processingTime: '3–4 weeks',
        highlight: 'Subsidised onboarding fees for approved e-marketplaces',
        url: 'https://mdec.my/etrade'),
    DisplayResource(name: 'Enterprise Development Grant (EDG)', type: 'Grant',
        provider: 'Enterprise Singapore',
        eligibility: 'Singapore-registered SMEs, min. 30% local equity',
        maxAmount: 'Up to 50% of qualifying costs', processingTime: '6–8 weeks',
        highlight: 'Covers capability development, innovation and internationalisation',
        url: 'https://www.enterprisesg.gov.sg/financial-support/enterprise-development-grant'),
    DisplayResource(name: 'Productivity Solutions Grant (PSG)', type: 'Grant',
        provider: 'Enterprise Singapore / IMDA',
        eligibility: 'Singapore-registered SMEs in approved sectors',
        maxAmount: 'Up to 50% of solution cost', processingTime: '4–6 weeks',
        highlight: 'Pre-approved list of digital and automation solutions ready to deploy',
        url: 'https://www.enterprisesg.gov.sg/financial-support/productivity-solutions-grant'),
    DisplayResource(name: 'SkillsFuture Enterprise Credit (SFEC)', type: 'Credit',
        provider: 'SkillsFuture Singapore',
        eligibility: 'Eligible employers with at least 3 Singapore employees',
        maxAmount: 'SGD 10,000 credit', processingTime: '2–4 weeks',
        highlight: 'Offsets costs of workforce transformation programmes',
        url: 'https://www.skillsfuture.gov.sg/sfec'),
    DisplayResource(name: 'KUR (Kredit Usaha Rakyat)', type: 'Loan',
        provider: 'Ministry of Finance / State Banks',
        eligibility: 'Indonesian MSMEs with valid business identity',
        maxAmount: 'IDR 500 million (micro tier)', processingTime: '1–2 weeks',
        highlight: 'Subsidised interest rate at 6% per annum for small businesses',
        url: 'https://kur.ekon.go.id'),
    DisplayResource(name: 'LPEI Export Financing', type: 'Loan',
        provider: 'Indonesia Eximbank (LPEI)',
        eligibility: 'Indonesian exporters, all sectors',
        maxAmount: 'IDR 10 billion+', processingTime: '4–8 weeks',
        highlight: 'Export buyer credit and working capital for exporters',
        url: 'https://www.lpei.go.id/en'),
    DisplayResource(name: 'PLUT-KUMKM Business Development', type: 'Free Service',
        provider: 'Ministry of Cooperatives & SMEs Indonesia',
        eligibility: 'All Indonesian SMEs',
        maxAmount: 'Free services', processingTime: 'Immediate',
        highlight: 'Free business consulting, training and mentoring centre network',
        url: 'https://www.depkop.go.id'),
    DisplayResource(name: 'SME Development Bank Soft Loan', type: 'Loan',
        provider: 'SME Development Bank of Thailand',
        eligibility: 'Thai-registered SMEs, max THB 500M annual revenue',
        maxAmount: 'THB 15 million', processingTime: '3–4 weeks',
        highlight: 'Below-market interest rates with flexible collateral options',
        url: 'https://www.smebank.co.th/en'),
    DisplayResource(name: 'BOI Smart SME Program', type: 'Incentive',
        provider: 'Board of Investment Thailand',
        eligibility: 'Thai SMEs in BOI target industries',
        maxAmount: 'Varies by project', processingTime: '8–12 weeks',
        highlight: 'Tax incentives and investment promotion for priority growth sectors',
        url: 'https://www.boi.go.th'),
    DisplayResource(name: 'DITP Export Promotion Grant', type: 'Grant',
        provider: 'Department of International Trade Promotion Thailand',
        eligibility: 'Thai exporters and SMEs',
        maxAmount: 'THB 200,000', processingTime: '4–6 weeks',
        highlight: 'Covers trade fair participation and international market development',
        url: 'https://www.ditp.go.th'),
    DisplayResource(name: 'SME Support Fund Credit Guarantee', type: 'Guarantee',
        provider: 'Vietnam Development Bank',
        eligibility: 'Vietnamese-registered SMEs',
        maxAmount: 'VND 5 billion', processingTime: '3–5 weeks',
        highlight: 'Credit guarantee to help SMEs access commercial bank loans',
        url: 'https://www.vdb.gov.vn'),
    DisplayResource(name: 'National SME Development Program', type: 'Free Service',
        provider: 'Ministry of Planning & Investment Vietnam',
        eligibility: 'All Vietnamese SMEs',
        maxAmount: 'Free training and consultation', processingTime: 'Immediate',
        highlight: 'Free business registration, legal consultation and market access support',
        url: 'https://business.gov.vn'),
    DisplayResource(name: 'MSME Credit Guarantee Program', type: 'Guarantee',
        provider: 'Philippine Guarantee Corporation (PhilGuarantee)',
        eligibility: 'Filipino MSMEs with bank accounts',
        maxAmount: 'PHP 5 million', processingTime: '2–4 weeks',
        highlight: 'Guarantee covers 70–80% of bank loan for easier bank approval',
        url: 'https://www.philguarantee.gov.ph'),
    DisplayResource(name: 'DTI Negosyo Center', type: 'Free Service',
        provider: 'Department of Trade & Industry Philippines',
        eligibility: 'All Filipino SMEs',
        maxAmount: 'Free services', processingTime: 'Walk-in same day',
        highlight: 'One-stop shop for registration, coaching and tech assistance',
        url: 'https://www.dti.gov.ph/negosyo/'),
    DisplayResource(name: 'SB Corp CARES Loan', type: 'Loan',
        provider: 'Small Business Corporation Philippines',
        eligibility: 'Filipino SMEs affected by economic disruption',
        maxAmount: 'PHP 5 million', processingTime: '2–3 weeks',
        highlight: 'Low-interest loans at 0.5% monthly with a grace period option',
        url: 'https://www.sbcorp.gov.ph'),
  ];

  static bool _isCountryMatch(DisplayResource r, String country) {
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

  // Renamed from _resolveResources to resolveResources (Public)
  static List<DisplayResource> resolveResources({
    required String country,
    required String milestoneTitle,
    required String milestoneDescription,
    required List<MilestoneResource> embedded,
  }) {
    final fromEmbedded = embedded.map(DisplayResource.fromEmbedded).toList();
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

  // ─── 4. SOS Prompt Builder ─────────────────────────────────────────────────

  // Renamed from _buildSosPrompt to buildSosPrompt (Public)
  static String buildSosPrompt({
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
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/subscription_controller.dart';
import '../model/app_theme.dart';
import 'main_shell.dart';

class SubscriptionGate extends ConsumerWidget {
  const SubscriptionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(subscriptionControllerProvider);
    if (membership.isActive) return const MainShell();
    return const SubscriptionScreen();
  }
}

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  final _referenceController = TextEditingController();

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionControllerProvider);
    final controller = ref.read(subscriptionControllerProvider.notifier);
    final waiting = state.status == MembershipStatus.loading;
    final pending = state.status == MembershipStatus.pending;

    if (state.status == MembershipStatus.needsSignIn) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Membership')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 48, color: AppTheme.green),
                SizedBox(height: 16),
                Text('Sign in required',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
                SizedBox(height: 8),
                Text(
                  'A monthly membership is linked to your account. Please sign in before completing the survey.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Membership')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D5A30), Color(0xFF1565C0)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.workspace_premium_rounded,
                      color: Colors.amber, size: 42),
                  SizedBox(height: 16),
                  Text('Unlock your growth roadmap',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 8),
                  Text('Personalised AI roadmap, milestones, financial tools, '
                      'and AI business coach.',
                      style: TextStyle(color: Colors.white70, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('RM5 / month',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Manual DuitNow payment with monthly access.'),
            const SizedBox(height: 24),
            if (pending) _PendingCard(onRefresh: controller.refresh) else ...[
              const Text('1. Pay using DuitNow',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              const SizedBox(height: 10),
              _QrPlaceholder(),
              const SizedBox(height: 16),
              const Text('2. Enter the payment reference from your bank app.',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              const SizedBox(height: 8),
              TextField(
                controller: _referenceController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'DuitNow payment reference',
                  hintText: 'Example: DN123456789',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: waiting
                    ? null
                    : () => controller.submitPaymentRequest(
                        _referenceController.text,
                      ),
                child: Text(waiting ? 'Submitting...' : 'I have paid RM5'),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: waiting ? null : controller.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh membership status'),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(state.errorMessage!,
                  style: const TextStyle(color: AppTheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3C873)),
        ),
        child: const Column(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Color(0xFFAA6B00), size: 36),
            SizedBox(height: 10),
            Text('Payment submitted for review',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            SizedBox(height: 6),
            Text('Your membership will unlock after we verify your DuitNow payment.'),
          ],
        ),
      );
}

class _QrPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Image.asset(
          'assets/images/duitnow_qr.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_2_rounded, size: 88, color: AppTheme.green),
                SizedBox(height: 12),
                Text('Add your verified DuitNow QR image as\nassets/images/duitnow_qr.png',
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
}

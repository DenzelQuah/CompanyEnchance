import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MembershipStatus { loading, needsSignIn, inactive, pending, active, error }

class SubscriptionState {
  const SubscriptionState({
    this.status = MembershipStatus.loading,
    this.periodEnd,
    this.errorMessage,
  });

  final MembershipStatus status;
  final DateTime? periodEnd;
  final String? errorMessage;

  bool get isActive => status == MembershipStatus.active;

  SubscriptionState copyWith({
    MembershipStatus? status,
    DateTime? periodEnd,
    String? errorMessage,
  }) => SubscriptionState(
    status: status ?? this.status,
    periodEnd: periodEnd ?? this.periodEnd,
    errorMessage: errorMessage,
  );
}

class SubscriptionController extends StateNotifier<SubscriptionState> {
  SubscriptionController() : super(const SubscriptionState()) {
    refresh();
  }

  final _supabase = Supabase.instance.client;

  Future<void> refresh() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      state = const SubscriptionState(status: MembershipStatus.needsSignIn);
      return;
    }
    state = const SubscriptionState(status: MembershipStatus.loading);
    try {
      final subscription = await _supabase
          .from('app_subscriptions')
          .select('status, current_period_end')
          .eq('user_id', user.id)
          .maybeSingle();
      final periodEnd = subscription?['current_period_end'] == null
          ? null
          : DateTime.tryParse(subscription!['current_period_end'] as String);
      final active = subscription?['status'] == 'active' &&
          periodEnd != null &&
          periodEnd.isAfter(DateTime.now());
      if (active) {
        state = SubscriptionState(
          status: MembershipStatus.active,
          periodEnd: periodEnd,
        );
        return;
      }

      final pending = await _supabase
          .from('subscription_payment_requests')
          .select('id')
          .eq('user_id', user.id)
          .eq('status', 'pending')
          .limit(1);
      state = SubscriptionState(
        status: (pending as List).isNotEmpty
            ? MembershipStatus.pending
            : MembershipStatus.inactive,
      );
    } catch (error) {
      state = SubscriptionState(
        status: MembershipStatus.error,
        errorMessage: 'Unable to check membership. Please try again.',
      );
    }
  }

  Future<void> submitPaymentRequest(String reference) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      state = const SubscriptionState(status: MembershipStatus.needsSignIn);
      return;
    }
    final trimmed = reference.trim();
    if (trimmed.length < 3) {
      state = const SubscriptionState(
        status: MembershipStatus.error,
        errorMessage: 'Enter the DuitNow payment reference from your bank app.',
      );
      return;
    }
    state = const SubscriptionState(status: MembershipStatus.loading);
    try {
      await _supabase.from('subscription_payment_requests').insert({
        'user_id': user.id,
        'plan_code': 'monthly_rm5',
        'amount_sen': 500,
        'payment_reference': trimmed,
      });
      state = const SubscriptionState(status: MembershipStatus.pending);
    } catch (error) {
      state = SubscriptionState(
        status: MembershipStatus.error,
        errorMessage: 'Could not submit the payment request. If you already '
            'submitted one, tap Refresh status.',
      );
    }
  }
}

final subscriptionControllerProvider =
    StateNotifierProvider<SubscriptionController, SubscriptionState>(
  (_) => SubscriptionController(),
);

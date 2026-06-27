import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/subscription_plan.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';

/// Checkout screen for a chosen [SubscriptionPlan].
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.plan});

  final SubscriptionPlan plan;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

enum _PaymentMethod { card, payPal }

class _PaymentScreenState extends State<PaymentScreen> {
  _PaymentMethod _method = _PaymentMethod.card;

  static const double _tax = 1.00;

  void _confirm() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        icon: Icon(
          Icons.check_circle_rounded,
          color: AppColors.positive,
          size: 48,
        ),
        title: const Text('Payment Successful'),
        content: Text(
          'Welcome to AetherPro! Your ${widget.plan.name} is now active.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.plan.price + _tax;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment'), leading: const BackButton()),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _buildMethodSelector(),
            const SizedBox(height: 24),
            if (_method == _PaymentMethod.card) _buildCardForm(),
            if (_method == _PaymentMethod.payPal) _buildPayPalNotice(),
            const SizedBox(height: 24),
            _buildOrderSummary(total),
            const SizedBox(height: 20),
            _buildSecurityNote(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MethodChip(
                label: 'Card',
                icon: Icons.credit_card_rounded,
                selected: _method == _PaymentMethod.card,
                onTap: () => setState(() => _method = _PaymentMethod.card),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MethodChip(
                label: 'PayPal',
                icon: Icons.account_balance_wallet_rounded,
                selected: _method == _PaymentMethod.payPal,
                onTap: () => setState(() => _method = _PaymentMethod.payPal),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Card Number'),
        TextField(
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: '1234 5678 9101 1121'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Expiry Date'),
                  TextField(
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(hintText: 'MM/YY'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('CVV'),
                  TextField(
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(hintText: '123'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _label('Cardholder Name'),
        TextField(
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'John Doe'),
        ),
      ],
    );
  }

  Widget _buildPayPalNotice() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "You'll be redirected to PayPal to complete your purchase "
              'securely.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(double total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Order Summary',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _summaryRow(
            'AetherPro (${widget.plan.period}ly)',
            Formatters.currency(widget.plan.price),
          ),
          const SizedBox(height: 12),
          _summaryRow('Tax', Formatters.currency(_tax)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _summaryRow('Total', Formatters.currency(total), emphasize: true),
        ],
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_rounded, color: AppColors.textTertiary, size: 16),
        const SizedBox(width: 8),
        Text(
          'Your payment information is encrypted and secure',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool emphasize = false}) {
    final style = TextStyle(
      color: emphasize ? AppColors.textPrimary : AppColors.textSecondary,
      fontSize: emphasize ? 18 : 14,
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}

class _MethodChip extends StatelessWidget {
  _MethodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.16) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

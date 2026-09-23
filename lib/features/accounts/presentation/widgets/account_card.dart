import 'package:flutter/material.dart';
import '../../domain/entities/account.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback? onTap;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
  });

  IconData _getAccountIcon(String type) {
    switch (type.toLowerCase()) {
      case 'digital':
        return Icons.phone_android;
      case 'checking':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings_outlined;
      case 'investment':
        return Icons.trending_up;
      case 'cash':
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  String _formatType(String type) {
    switch (type.toLowerCase()) {
      case 'digital':
        return 'Conta Digital';
      case 'checking':
        return 'Conta Corrente';
      case 'savings':
        return 'Poupança';
      case 'investment':
        return 'Investimentos';
      case 'cash':
        return 'Dinheiro / Carteira';
      default:
        return type;
    }
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNegative = account.currentBalance < 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            _getAccountIcon(account.type),
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          account.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          _formatType(account.type),
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatCurrency(account.currentBalance),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isNegative
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
              ),
            ),
            Text(
              'Saldo atual',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

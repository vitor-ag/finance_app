import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/design/category_style.dart';
import '../../../../core/design/components.dart';
import '../../domain/entities/account.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.onArchive,
  });
  final Account account;
  final VoidCallback? onTap, onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (type, fallback) = switch (account.type) {
      'digital' => ('Conta digital', Symbols.smartphone_rounded),
      'checking' => ('Conta corrente', Symbols.account_balance_rounded),
      'savings' => ('Poupança', Symbols.savings_rounded),
      'investment' => ('Investimentos', Symbols.trending_up_rounded),
      'cash' => ('Dinheiro / carteira', Symbols.account_balance_wallet_rounded),
      _ => (account.type, Symbols.account_balance_wallet_rounded),
    };
    final tint = storedColor(account.color) ?? theme.colorScheme.primary;
    return AppSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppIcon(
                financialIcons[account.icon]?.$1 ?? fallback,
                color: tint,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name, style: theme.textTheme.titleMedium),
                    Text(
                      account.isActive ? type : '$type · Arquivada',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (onArchive != null)
                PopupMenuButton<String>(
                  tooltip: 'Ações da conta',
                  icon: const Icon(Symbols.more_vert_rounded),
                  onSelected: (_) => onArchive!(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'archive',
                      child: Text('Arquivar conta'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Saldo atual', style: theme.textTheme.labelMedium),
          MoneyText(
            account.currentBalanceCents,
            style: theme.textTheme.headlineSmall,
            kind: account.currentBalanceCents < 0
                ? MoneyKind.expense
                : MoneyKind.neutral,
          ),
        ],
      ),
    );
  }
}

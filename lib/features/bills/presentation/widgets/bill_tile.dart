import 'package:flutter/material.dart';
import '../../domain/entities/bill.dart';

class BillTile extends StatelessWidget {
  final Bill bill;
  final String? categoryName;
  final VoidCallback? onMarkAsPaid;

  const BillTile({
    super.key,
    required this.bill,
    this.categoryName,
    this.onMarkAsPaid,
  });

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Paga';
      case 'overdue':
        return 'Atrasada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return 'Pendente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = bill.effectiveStatus;
    final color = _statusColor(status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.receipt_long, color: color, size: 20),
        ),
        title: Text(
          bill.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          'Vence em ${bill.dueDate.day}/${bill.dueDate.month}/${bill.dueDate.year}'
          '${categoryName != null ? ' · $categoryName' : ''}',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatCurrency(bill.amount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusLabel(status),
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        onTap: (status == 'pending' || status == 'overdue')
            ? onMarkAsPaid
            : null,
      ),
    );
  }
}
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/mock/mock_data.dart';
import '../../../models/transaction_model.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final totalYield = mockTransactions
        .where((t) => t.amount > 0 && t.type == 'yield')
        .fold<double>(0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: Text('Mi Historial', style: titleBold(20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // RESUMEN
          SliverToBoxAdapter(
            child: FadeInDown(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: successGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total ganado en rendimientos', style: bodyText(13, color: softGray)),
                            Text(
                              '+\$${totalYield.toStringAsFixed(2)} MXN',
                              style: titleBold(22, color: successGreen),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Tandas completadas', style: bodyText(12, color: softGray)),
                          Text('1', style: titleBold(22, color: accentGold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // HEADER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('Transacciones', style: titleSemi(16)),
            ),
          ),

          // LISTA
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: mockTransactions.length,
              itemBuilder: (ctx, i) {
                final t = mockTransactions[i];
                return FadeInUp(
                  delay: Duration(milliseconds: i * 80),
                  child: _TransactionTile(transaction: t),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final info = _typeInfo(transaction.type);
    final positive = transaction.amount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: info.color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: info.color.withOpacity(0.15),
                ),
                child: Icon(info.icon, color: info.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaction.description, style: bodyText(14, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(transaction.date, style: bodyText(12, color: softGray)),
                  ],
                ),
              ),
              Text(
                '${positive ? '+' : ''}\$${transaction.amount.abs().toStringAsFixed(2)}',
                style: titleSemi(15,
                    color: positive ? successGreen : warningRed),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Text(
                  'Ver en blockchain →',
                  style: bodyText(11, color: softGray),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _TxInfo _typeInfo(String type) {
    switch (type) {
      case 'yield':
        return _TxInfo(Icons.trending_up_rounded, successGreen);
      case 'claim':
        return _TxInfo(Icons.emoji_events_rounded, accentGold);
      case 'frozen':
        return _TxInfo(Icons.lock_rounded, Colors.lightBlue);
      default: // deposit
        return _TxInfo(Icons.payments_rounded, warningRed);
    }
  }
}

class _TxInfo {
  const _TxInfo(this.icon, this.color);
  final IconData icon;
  final Color color;
}

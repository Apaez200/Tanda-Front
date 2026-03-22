import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/contract_constants.dart';
import '../../../core/prototype_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../injection.dart';
import '../../../models/tanda_error_model.dart';
import '../../../data/implementations/soroban/soroban_tanda_repository.dart';
import '../../../data/implementations/soroban/soroban_wallet_repository.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/deposit_slider_widget.dart';

class DepositScreen extends StatelessWidget {
  const DepositScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DepositView();
  }
}

class DepositView extends StatefulWidget {
  const DepositView({super.key});

  @override
  State<DepositView> createState() => _DepositViewState();
}

class _DepositViewState extends State<DepositView> {
  final _fmt =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
  DepositProjection? _proj;
  bool _loading = false;
  String _statusText = '';

  double _amount = 1000.0;
  final int _todayDay = DateTime.now().day;

  @override
  void initState() {
    super.initState();
    _loadAmount();
  }

  Future<void> _loadAmount() async {
    try {
      final config = await tandaRepository.getConfig();
      if (mounted) {
        setState(() => _amount = config.paymentAmountMXN);
      }
    } catch (_) {
      // Use default
    }
  }

  void _onDeposit() async {
    setState(() {
      _loading = true;
      _statusText = 'Preparando transacción...';
    });

    try {
      final secretKey = await walletRepository.getSavedSecretKey();
      if (secretKey == null || secretKey.isEmpty) {
        throw TandaException(TandaContractError.unknown,
            rawMessage: 'No hay wallet conectada');
      }

      // Approve USDC allowance first
      setState(() => _statusText = 'Aprobando USDC...');
      if (walletRepository is SorobanWalletRepository) {
        final repo = walletRepository as SorobanWalletRepository;
        final activeContract = tandaRepository is SorobanTandaRepository
            ? (tandaRepository as SorobanTandaRepository).contractId
            : null;
        await repo.approveUsdcAllowance(
          signerSecretKey: secretKey,
          amount: ContractConstants.paymentAmountStroops,
          tandaContractOverride: activeContract,
        );
      }

      if (!mounted) return;

      // Make payment
      setState(() => _statusText = 'Enviando pago al contrato...');
      final txHash =
          await tandaRepository.makePayment(signerSecretKey: secretKey);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _statusText = '';
      });
      _showSuccess(txHash);
    } on TandaException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _statusText = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: cardBg,
            content: Text(e.error.userMessage,
                style: bodyText(13, color: warningRed)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _statusText = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: cardBg,
            content:
                Text('Error: $e', style: bodyText(13, color: warningRed)),
          ),
        );
      }
    }
  }

  void _showSuccess(String txHash) {
    final days = _proj?.daysInvested ?? 15;
    final yield_ = _proj?.projectedYield ?? 0;
    final total = _amount + yield_;
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text('¡Listo! Tu dinero ya está trabajando',
                  style: titleBold(20, color: successGreen),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),
            _row('Depositaste', _fmt.format(_amount)),
            _row('Días invertidos', '$days días'),
            _row('Recibirás aprox.', _fmt.format(total)),
            const SizedBox(height: 8),
            SelectableText(
              'TX: ${txHash.substring(0, 16)}...',
              style: bodyText(11, color: softGray),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Volver al inicio',
              onPressed: () {
                userDepositedNotifier.value = true;
                Navigator.pop(parentContext);
                parentContext.pop(); // go back to dashboard
              },
              variant: CustomButtonVariant.primary,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: bodyText(14, color: softGray)),
            Text(v,
                style:
                    bodyText(14, color: offWhite, weight: FontWeight.w600)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final amount = _amount;
    final days = _proj?.daysInvested ?? 15;
    final yield_ = _proj?.projectedYield ?? 0;
    const dailyNetAPY = 0.000246;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: Text('Depositar', style: titleBold(20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MONTO
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: accentGold.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿Cuánto vas a depositar?',
                        style: bodyText(14, color: softGray)),
                    const SizedBox(height: 8),
                    Text(_fmt.format(amount),
                        style: titleBold(42, color: accentGold)),
                    Text('Este es tu monto de la ronda',
                        style: bodyText(13, color: softGray)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SLIDER
            FadeInUp(
              delay: const Duration(milliseconds: 150),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿Cuándo depositas?',
                        style: titleSemi(16)),
                    const SizedBox(height: 16),
                    DepositSliderWidget(
                      minDay: 1,
                      maxDay: 29,
                      amount: amount,
                      dailyNetAPY: dailyNetAPY,
                      todayDay: _todayDay.clamp(1, 29),
                      onProjectionChanged: (p) =>
                          setState(() => _proj = p),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // RESUMEN
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: primaryGreen.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumen', style: titleSemi(16)),
                    const SizedBox(height: 12),
                    _row('Depositas', _fmt.format(amount)),
                    _row('Días invertidos', '$days días'),
                    const Divider(
                        height: 20, color: Color(0xFF2A2A2A)),
                    _row(
                      'Recibirás aprox.',
                      _fmt.format(amount + yield_),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // STATUS
            if (_statusText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Center(
                  child: Text(_statusText,
                      style: bodyText(13, color: accentGold)),
                ),
              ),

            // CTA
            CustomButton(
              label: 'Depositar y poner a trabajar mi dinero',
              onPressed: _loading ? null : _onDeposit,
              variant: CustomButtonVariant.primary,
              loading: _loading,
              fullWidth: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

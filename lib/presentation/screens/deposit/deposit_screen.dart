import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/contract_constants.dart';
import '../../../core/prototype_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/mock/mock_state.dart';
import '../../../injection.dart';
import '../../../models/tanda_error_model.dart';
import '../../widgets/custom_button.dart';

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
  final _amountController = TextEditingController();
  bool _loading = false;
  String _statusText = '';

  double _amount = 0;

  /// CETES retention = 10% of the deposited amount.
  double get _cetesRetention => _amount * 0.10;

  @override
  void initState() {
    super.initState();
    _amountController.text = '1000';
    _amount = 1000;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _netToBeneficiary => _amount - _cetesRetention;

  bool get _canDeposit => _amount > 0;

  void _onDeposit() async {
    if (!_canDeposit) return;

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

      if (!ContractConstants.useMock) {
        setState(() => _statusText = 'Aprobando USDC...');
      }

      if (!mounted) return;

      // Pass the user-entered amount to mock state
      if (ContractConstants.useMock) {
        MockState.instance.lastDepositAmount = _amount;
      }

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
            if (_amount > _cetesRetention) ...[
              _row('Retención CETES', '-${_fmt.format(_cetesRetention)}'),
              _row('Al beneficiario', _fmt.format(_netToBeneficiary)),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: successGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded,
                      color: successGreen, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_fmt.format(_cetesRetention)} invertidos en CETES generando rendimiento',
                      style: bodyText(11, color: successGreen),
                    ),
                  ),
                ],
              ),
            ),
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
                parentContext.pop();
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
            // MONTO LIBRE
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: accentGold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿Cuánto quieres depositar?',
                        style: bodyText(14, color: softGray)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0B10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentGold.withValues(alpha: 0.3),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text('\$',
                              style: titleBold(28, color: accentGold)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              style: titleBold(28, color: offWhite),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '0.00',
                                hintStyle: titleBold(28,
                                    color: const Color(0xFF3A3C48)),
                              ),
                              onChanged: (v) {
                                final parsed = double.tryParse(
                                    v.replaceAll(',', ''));
                                setState(() {
                                  _amount = parsed ?? 0;
                                });
                              },
                            ),
                          ),
                          Text('MXN',
                              style: bodyText(13,
                                  color: const Color(0xFF6B6D7B),
                                  weight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Quick amount chips
                    Row(
                      children: [
                        for (final amt in [500, 1000, 2500, 5000])
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: GestureDetector(
                                onTap: () {
                                  setState(
                                      () => _amount = amt.toDouble());
                                  _amountController.text = amt.toString();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _amount == amt
                                        ? accentGold
                                            .withValues(alpha: 0.12)
                                        : const Color(0xFF1A1B24),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _amount == amt
                                          ? accentGold
                                              .withValues(alpha: 0.4)
                                          : const Color(0xFF1E1F2A),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '\$${amt >= 1000 ? '${(amt / 1000).toStringAsFixed(0)}k' : '$amt'}',
                                      style: bodyText(12,
                                          color: _amount == amt
                                              ? accentGold
                                              : const Color(0xFF6B6D7B),
                                          weight: _amount == amt
                                              ? FontWeight.w600
                                              : FontWeight.w400),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // DISTRIBUCIÓN DEL PAGO
            if (_amount > 0)
              FadeInUp(
                delay: const Duration(milliseconds: 150),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: accentGold.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_rounded,
                              color: accentGold, size: 18),
                          const SizedBox(width: 8),
                          Text('Distribución del pago',
                              style: titleSemi(15)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _row('Pago total', _fmt.format(_amount)),
                      _row('Inversión CETES',
                          '-${_fmt.format(_cetesRetention)}'),
                      const Divider(
                          height: 16, color: Color(0xFF2A2A2A)),
                      _row('Fluye al beneficiario',
                          _fmt.format(_netToBeneficiary)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  primaryGreen.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: successGreen, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '10% (${_fmt.format(_cetesRetention)}) se retiene e invierte en CETES para generar rendimiento',
                                style:
                                    bodyText(11, color: successGreen),
                              ),
                            ),
                          ],
                        ),
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
              label: _canDeposit
                  ? 'Depositar ${_fmt.format(_amount)}'
                  : 'Ingresa un monto',
              onPressed:
                  _loading || !_canDeposit ? null : _onDeposit,
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

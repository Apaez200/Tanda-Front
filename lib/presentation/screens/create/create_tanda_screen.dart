import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/contract_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/tanda_storage_service.dart';
import '../../../injection.dart';

const _bg = Color(0xFF060608);
const _cardColor = Color(0xFF0E0F14);
const _borderColor = Color(0xFF1E1F2A);
const _mint = Color(0xFF0CFFC5);
const _purple = Color(0xFF6C63FF);

class CreateTandaScreen extends StatefulWidget {
  const CreateTandaScreen({super.key});

  @override
  State<CreateTandaScreen> createState() => _CreateTandaScreenState();
}

class _CreateTandaScreenState extends State<CreateTandaScreen> {
  final _fmt =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
  final _amountController = TextEditingController(text: '1000');
  final _amountFocus = FocusNode();

  // Config
  int _maxParticipants = 5;
  double _paymentAmount = 1000;
  int _periodDays = 30;

  // State
  bool _isCreating = false;
  String _statusText = '';

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  double get _totalPool => _paymentAmount * _maxParticipants;
  double get _collateral => _paymentAmount * 0.10;
  double get _invested => _paymentAmount * 0.90;
  int get _durationMonths {
    final m = _maxParticipants * _periodDays / 30;
    return m < 1 ? 1 : m.round();
  }

  Future<void> _createTanda() async {
    setState(() {
      _isCreating = true;
      _statusText = 'Creando tu grupo...';
    });

    // Simulate creation delay (the contract is already deployed on testnet)
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _statusText = 'Configurando grupo...');
    await Future.delayed(const Duration(milliseconds: 800));

    // Use the existing deployed contract for this prototype
    final contractId = ContractConstants.tandaContractId;
    final name =
        'Grupo ${_fmt.format(_paymentAmount)} x $_maxParticipants';

    await tandaStorage.saveTanda(SavedTanda(
      contractId: contractId,
      name: name,
      role: 'admin',
      joinedAt: DateTime.now(),
    ));
    setActiveTandaContract(contractId);

    if (mounted) {
      setState(() {
        _isCreating = false;
        _statusText = '';
      });
      _showSuccessSheet(name, contractId);
    }
  }

  void _showSuccessSheet(String name, String contractId) {
    final parentContext = context; // capture stable context
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: _mint, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2B35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),

            // Success icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _mint.withValues(alpha: 0.1),
                border: Border.all(
                    color: _mint.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.check_rounded,
                  color: _mint, size: 36),
            ),
            const SizedBox(height: 20),

            Text('Tu grupo está listo',
                style: titleBold(22, color: _mint)),
            const SizedBox(height: 8),
            Text(
              'Ahora invita a tus amigos para que se unan.',
              style: bodyText(14, color: const Color(0xFF6B6D7B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Tanda summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                children: [
                  _SuccessRow('Nombre', name),
                  _SuccessRow('Participantes', '$_maxParticipants personas'),
                  _SuccessRow('Pago por ronda',
                      _fmt.format(_paymentAmount)),
                  _SuccessRow('Cada', '$_periodDays días'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Invite button
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(
                    text:
                        'Únete a mi grupo en Rendix! Código: $contractId'));
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    backgroundColor: _cardColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    content: Text(
                        'Invitación copiada — envíala a tus amigos',
                        style: bodyText(13, color: _mint)),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _mint.withValues(alpha: 0.1),
                  border: Border.all(color: _mint.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.share_rounded,
                        color: _mint, size: 18),
                    const SizedBox(width: 8),
                    Text('Copiar invitación para mis amigos',
                        style: bodyText(14,
                            color: _mint, weight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Go to dashboard
            GestureDetector(
              onTap: () {
                Navigator.pop(parentContext);
                parentContext.go('/dashboard');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [accentGold, Color(0xFFB8892E)],
                  ),
                ),
                child: Center(
                  child: Text('Ver mi grupo',
                      style: bodyText(15,
                          color: _bg, weight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: offWhite),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: accentGold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text('Crear Grupo', style: titleSemi(18, color: offWhite)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        'Elige cuántos amigos, cuánto aportar y cada cuánto.',
                        style:
                            bodyText(14, color: const Color(0xFF6B6D7B)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // PARTICIPANTS
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: _ParamCard(
                        icon: Icons.people_alt_rounded,
                        label: 'Amigos en el grupo',
                        value: '$_maxParticipants',
                        valueColor: _mint,
                        child: Row(
                          children: [
                            _StepButton(
                              icon: Icons.remove_rounded,
                              color: _mint,
                              onTap: _maxParticipants > 2
                                  ? () => setState(() => _maxParticipants--)
                                  : null,
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _maxParticipants.clamp(0, 10),
                                  (i) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                                    child: Icon(Icons.person_rounded,
                                        color: _mint.withValues(alpha: 0.5 + (i / _maxParticipants) * 0.5),
                                        size: _maxParticipants > 7 ? 16 : 20),
                                  ),
                                ),
                              ),
                            ),
                            if (_maxParticipants > 10)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text('+${_maxParticipants - 10}',
                                    style: bodyText(12, color: _mint, weight: FontWeight.w600)),
                              ),
                            _StepButton(
                              icon: Icons.add_rounded,
                              color: _mint,
                              onTap: _maxParticipants < 20
                                  ? () => setState(() => _maxParticipants++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // PAYMENT AMOUNT
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.paid_rounded,
                                    color: Color(0xFF3A3C48), size: 18),
                                const SizedBox(width: 8),
                                Text('Cada quien aporta',
                                    style: bodyText(13,
                                        color: const Color(0xFF6B6D7B))),
                              ],
                            ),
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
                                      style: titleBold(24, color: accentGold)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _amountController,
                                      focusNode: _amountFocus,
                                      keyboardType: TextInputType.number,
                                      style: titleBold(24, color: offWhite),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '1000',
                                        hintStyle: titleBold(24,
                                            color: const Color(0xFF3A3C48)),
                                      ),
                                      onChanged: (v) {
                                        final parsed = double.tryParse(
                                            v.replaceAll(',', ''));
                                        if (parsed != null && parsed >= 100) {
                                          setState(
                                              () => _paymentAmount = parsed);
                                        }
                                      },
                                    ),
                                  ),
                                  Text('MXN',
                                      style: bodyText(12,
                                          color: const Color(0xFF6B6D7B),
                                          weight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Quick amount chips
                            Row(
                              children: [
                                for (final amount in [500, 1000, 2500, 5000])
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() => _paymentAmount =
                                              amount.toDouble());
                                          _amountController.text =
                                              amount.toString();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _paymentAmount == amount
                                                ? accentGold
                                                    .withValues(alpha: 0.12)
                                                : const Color(0xFF1A1B24),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: _paymentAmount == amount
                                                  ? accentGold
                                                      .withValues(alpha: 0.4)
                                                  : _borderColor,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '\$${amount >= 1000 ? '${(amount / 1000).toStringAsFixed(0)}k' : '$amount'}',
                                              style: bodyText(11,
                                                  color: _paymentAmount ==
                                                          amount
                                                      ? accentGold
                                                      : const Color(
                                                          0xFF6B6D7B),
                                                  weight: _paymentAmount ==
                                                          amount
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
                            if (_paymentAmount < 100)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('Monto minimo: \$100',
                                    style: bodyText(11,
                                        color: const Color(0xFFE74C3C))),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // PERIOD
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: _ParamCard(
                        icon: Icons.calendar_today_rounded,
                        label: 'Se juntan cada',
                        value: _periodDays == 7
                            ? 'Semana'
                            : _periodDays == 15
                                ? 'Quincena'
                                : 'Mes',
                        valueColor: _purple,
                        child: Row(
                          children: [
                            _PeriodOption(
                              label: 'Semanal',
                              selected: _periodDays == 7,
                              onTap: () =>
                                  setState(() => _periodDays = 7),
                            ),
                            const SizedBox(width: 8),
                            _PeriodOption(
                              label: 'Quincenal',
                              selected: _periodDays == 15,
                              onTap: () =>
                                  setState(() => _periodDays = 15),
                            ),
                            const SizedBox(width: 8),
                            _PeriodOption(
                              label: 'Mensual',
                              selected: _periodDays == 30,
                              onTap: () =>
                                  setState(() => _periodDays = 30),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SUMMARY — user-friendly
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: accentGold.withValues(alpha: 0.12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded,
                                    color: accentGold, size: 16),
                                const SizedBox(width: 8),
                                Text('Así funciona tu grupo',
                                    style: bodyText(13,
                                        color: accentGold,
                                        weight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _SumRow(
                                'Cada ronda se juntan',
                                _fmt.format(_totalPool)),
                            _SumRow(
                                'Tu aportación',
                                _fmt.format(_paymentAmount)),
                            _SumRow(
                                'Protección (se te regresa)',
                                _fmt.format(_collateral)),
                            _SumRow(
                                'Se invierte para ganar más',
                                _fmt.format(_invested)),
                            _SumRow('Turnos para recibir',
                                '$_maxParticipants'),
                            _SumRow('Dura aproximadamente',
                                '$_durationMonths meses'),
                          ],
                        ),
                      ),
                    ),

                    // How it works hint
                    const SizedBox(height: 16),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 350),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _mint.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _mint.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded,
                                color: _mint, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Cada turno, todos aportan y una persona recibe el dinero. Mientras tanto, tu inversión genera rendimientos en CETES.',
                                style: bodyText(12,
                                    color: const Color(0xFF6B6D7B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // STATUS
            if (_statusText.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: accentGold),
                    ),
                    const SizedBox(width: 10),
                    Text(_statusText,
                        style: bodyText(13, color: accentGold)),
                  ],
                ),
              ),

            // BOTTOM BUTTON
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: _bg,
                  border: Border(
                    top: BorderSide(color: _borderColor, width: 1),
                  ),
                ),
                child: GestureDetector(
                  onTap: _isCreating ? null : _createTanda,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: _isCreating
                            ? [
                                const Color(0xFF3A3C48),
                                const Color(0xFF2A2B35),
                              ]
                            : [accentGold, const Color(0xFFB8892E)],
                      ),
                      boxShadow: _isCreating
                          ? []
                          : [
                              BoxShadow(
                                color:
                                    accentGold.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Center(
                      child: _isCreating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: offWhite),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                    Icons.rocket_launch_rounded,
                                    color: _bg,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text('Crear mi grupo',
                                    style: bodyText(16,
                                        color: _bg,
                                        weight: FontWeight.w700)),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── WIDGETS ────────────────────────────────────────────────────────────────

class _ParamCard extends StatelessWidget {
  const _ParamCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.child,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF3A3C48), size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: bodyText(13, color: const Color(0xFF6B6D7B))),
              const Spacer(),
              Text(value,
                  style: bodyText(16,
                      color: valueColor, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _PeriodOption extends StatelessWidget {
  const _PeriodOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? _purple.withValues(alpha: 0.12)
                : const Color(0xFF1A1B24),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? _purple.withValues(alpha: 0.4)
                  : _borderColor,
            ),
          ),
          child: Center(
            child: Text(label,
                style: bodyText(12,
                    color: selected ? _purple : softGray,
                    weight:
                        selected ? FontWeight.w600 : FontWeight.w400)),
          ),
        ),
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  const _SumRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: bodyText(12, color: const Color(0xFF6B6D7B))),
          ),
          Text(value,
              style: bodyText(12,
                  color: offWhite, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.12)
              : const Color(0xFF1A1B24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: 0.3)
                : _borderColor,
          ),
        ),
        child: Icon(icon,
            color: enabled ? color : const Color(0xFF3A3C48), size: 20),
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  const _SuccessRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: bodyText(12, color: const Color(0xFF6B6D7B))),
          Text(value,
              style: bodyText(12,
                  color: offWhite, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cycle_estimate.dart';
import '../providers/cycle_provider.dart';

/// Mi ciclo (Bloque 3 · mockup aprobado C1–C4): el ciclo como estación
/// interior. No es un tracker de fertilidad ni un calendario que exige — es
/// contexto para que Aura acompañe mejor. Posparto/lactancia es un estado
/// VÁLIDO de primera clase, no un error (C1). Todo opt-in, todo borrable.
class CycleScreen extends ConsumerStatefulWidget {
  const CycleScreen({super.key});

  @override
  ConsumerState<CycleScreen> createState() => _CycleScreenState();
}

/// Predicciones de fertilidad (ovulación, ventana fértil): OCULTAS por
/// decisión de producto (jul 2026). El código queda intacto y se reactiva
/// cambiando esta bandera, pero hoy NO se muestran porque:
///   · afirmar probabilidad de embarazo acerca la app a producto sanitario
///     (precedente Natural Cycles: ensayos clínicos + marcado CE/FDA);
///   · el modelo de 28 días fijos ignora la regularidad que ella declaró —
///     a un cuerpo irregular le hablaría con una certeza que no existe;
///   · Aura acompaña, no mide: una ventana fértil pone al cuerpo a rendir
///     cuentas contra una norma (y duele distinto en posparto, en pérdida
///     o buscando embarazo).
/// Si algún día se activa, es producto aparte y con revisión legal.
const bool showFertilityInsights = false;

/// Copy por estación. Winter es HECHO registrado; el resto habla con "may"
/// (GUARD_MENS_04: una estimación jamás se presenta como certeza).
const _seasonCopy = {
  'winter': (
    '🌑',
    'Winter',
    'Bleeding days — your body asks for softness. '
        'Aura keeps your gestures at their gentlest.',
  ),
  'spring': (
    '🌱',
    'It may be spring inside',
    'Energy often returns little by little around now. No rush — it comes '
        'when it comes.',
  ),
  'summer': (
    '☀️',
    'It may be summer inside',
    'Brighter, steadier days often land here. Enjoy them your way.',
  ),
  'autumn': (
    '🍂',
    'It may be autumn inside',
    'Softer days may be near, so Aura eases the pace a little.',
  ),
};

class _CycleScreenState extends ConsumerState<CycleScreen> {
  bool _settingUp = false; // C1b visible (eligió "I get my period")
  DateTime? _pickedDate;
  bool _notSureDate = false;
  String _regularity = 'not_sure';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Polling suave: al entrar refetchea (mismo patrón que el resto de tabs).
    Future.microtask(() {
      if (mounted) ref.invalidate(cycleProvider);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      // El próximo gesto reintenta; el ciclo jamás regaña ni bloquea.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cycle = ref.watch(cycleProvider);

    return Scaffold(
      body: SafeArea(
        child: cycle.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(cycleProvider),
              child: const Text('Try again'),
            ),
          ),
          data: (view) {
            if (_settingUp) return _setup(context);
            if (view == null) return _invitation(context);
            return switch (view.mode) {
              'tracking' => _tracking(context, view),
              'paused' => _paused(context),
              _ => _off(context),
            };
          },
        ),
      ),
    );
  }

  // --- C1 · invitación (opt-in real) ---------------------------------------
  Widget _invitation(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        const Text('MY CYCLE', style: AppTypography.sectionLabel),
        const SizedBox(height: 10),
        Text(
          'If you want, tell me about your cycle.',
          style: _serif(context),
        ),
        const SizedBox(height: 6),
        const Text(
          "It helps me shape your days with more care. It's never required, "
          'nothing is predicted without asking, and you can turn it off — or '
          'erase it all — whenever you want.',
          style: TextStyle(
              fontSize: 12.5, height: 1.55, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),
        _door(
          'I get my period',
          'Two small questions, only if you know them.',
          () => setState(() => _settingUp = true),
        ),
        _door(
          'Not right now (postpartum, breastfeeding…)',
          "A valid season of its own. I won't ask again.",
          () => _run(() => setupCycle(ref, mode: 'paused')),
        ),
        _door(
          "I'd rather not share this",
          'Nothing is stored beyond this choice.',
          () => _run(() => setupCycle(ref, mode: 'off')),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            '🔒 This stays between you and Aura. Never in notifications, '
            'never shared with anyone — not even a support person. You can '
            'delete it completely, any time.',
            style: TextStyle(
                fontSize: 11.5, height: 1.55, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  // --- C1b · lo mínimo, con salidas ------------------------------------------
  Widget _setup(BuildContext context) {
    final dateLabel = _notSureDate
        ? 'Not sure'
        : _pickedDate == null
            ? 'Pick a date'
            : '${_pickedDate!.year}-${_pickedDate!.month.toString().padLeft(2, '0')}-${_pickedDate!.day.toString().padLeft(2, '0')}';
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        const Text('MY CYCLE', style: AppTypography.sectionLabel),
        const SizedBox(height: 10),
        Text('Two things, only if you know them.', style: _serif(context)),
        const SizedBox(height: 18),
        const Text('When did your last period start?',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _chip(dateLabel, _pickedDate != null && !_notSureDate, _pickDate),
          _chip('Not sure', _notSureDate, () {
            setState(() {
              _notSureDate = true;
              _pickedDate = null;
            });
          }),
        ]),
        const SizedBox(height: 18),
        const Text('How regular is your cycle?',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text(
          '"Irregular" and "not sure" are complete answers — then Aura only '
          'follows what you log, never guesses.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (value, label) in [
            ('regular', 'Pretty regular'),
            ('irregular', 'Irregular'),
            ('not_sure', 'Not sure'),
          ])
            _chip(label, _regularity == value,
                () => setState(() => _regularity = value)),
        ]),
        const SizedBox(height: 26),
        _primary('Save', () async {
          await _run(() => setupCycle(
                ref,
                mode: 'tracking',
                regularity: _regularity,
                lastPeriodStart: _notSureDate ? null : _pickedDate,
              ));
          if (mounted) setState(() => _settingUp = false);
        }),
        TextButton(
          onPressed: () => setState(() => _settingUp = false),
          child: const Text('← Back',
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _pickedDate = picked;
        _notSureDate = false;
      });
    }
  }

  // --- C2 + C4 · registrando -------------------------------------------------
  /// Vista rica del mockup "My Cycle": hero por fase, rueda de 28 días,
  /// tarjetas de ovulación / próxima regla / ventana fértil y stats. Todo es
  /// ESTIMACIÓN con modelo de 28 días desde el último inicio de regla (nunca
  /// un tracker clínico; el tono "estimate, never a verdict" manda). Sin fecha
  /// registrada -> vista mínima honesta (_trackingNoDate).
  Widget _tracking(BuildContext context, CycleView view) {
    final last = view.lastPeriodStart;
    if (last == null) return _trackingNoDate(context, view);

    final est = CycleEstimate.from(last, DateTime.now());
    final phase = est.phase;
    final fert = est.fertility;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        Center(
          child: Text('My Cycle',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: AppColors.primary,
                    fontStyle: FontStyle.italic,
                  )),
        ),
        Center(
          child: Text('Phase ${phase.name.toLowerCase()}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 10),
        Center(
          child:
              Image.asset(phase.heroAsset, height: 180, fit: BoxFit.contain),
        ),
        const SizedBox(height: 10),
        Center(
          child: _outlinePill('Day ${est.cycleDay} of '
              '${CycleEstimate.cycleLength} · ${phase.micro}'),
        ),
        const SizedBox(height: 16),
        _CycleWheel(cycleDay: est.cycleDay),
        const SizedBox(height: 12),
        _legend(),
        const SizedBox(height: 20),
        _phaseMessageCard(phase),
        const SizedBox(height: 12),
        _auraAdaptsCard(),
        const SizedBox(height: 12),
        // Ovulación + próxima regla + ventana fértil: ocultas (ver
        // showFertilityInsights). El widget sigue vivo para reactivarlas.
        if (showFertilityInsights) ...[
          Row(children: [
            Expanded(
              child: _infoCard(
                icon: Icons.egg_alt_outlined,
                tint: const Color(0xFFEAF7EF),
                iconColor: const Color(0xFF2E9E5B),
                title: 'Ovulation',
                pill: est.daysToOvulation == 0
                    ? 'today'
                    : 'in ${est.daysToOvulation} days',
                pillColor: const Color(0xFF2E9E5B),
                pillBg: const Color(0xFFEAF7EF),
                detail: 'Day ${CycleEstimate.ovulationDay}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoCard(
                icon: Icons.water_drop_outlined,
                tint: const Color(0xFFFCE3EC),
                iconColor: AppColors.primary,
                title: 'Next Period',
                pill: est.inPeriod ? 'now' : 'in ${est.daysToNextPeriod} days',
                pillColor: AppColors.primary,
                pillBg: const Color(0xFFFCE3EC),
                detail: est.inPeriod
                    ? 'Day ${est.cycleDay} of period'
                    : 'Around day ${CycleEstimate.cycleLength}',
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _fertilityCard(fert),
          const SizedBox(height: 12),
        ],
        Row(children: [
          Expanded(
            child: _statTile('${CycleEstimate.cycleLength}', 'Avg Cycle',
                CupertinoIcons.calendar, const Color(0xFFEAF0FB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statTile('${CycleEstimate.periodDays}', 'Period Days',
                Icons.water_drop_outlined, const Color(0xFFFDE7EE)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statTile(_regularityLabel(view.regularity), 'Regularity',
                CupertinoIcons.checkmark_circle, const Color(0xFFFBF3E2)),
          ),
        ]),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'An estimate from a 28-day model — never a verdict. '
            'Your body has the final word.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: AppColors.textSecondary.withValues(alpha: 0.9)),
          ),
        ),
        const SizedBox(height: 22),
        _primary('My period started today',
            () => _run(() => logPeriodStart(ref))),
        const SizedBox(height: 22),
        const Text('SETTINGS', style: AppTypography.sectionLabel),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show the season chip on Home',
              style: TextStyle(fontSize: 13.5)),
          value: view.showChip,
          activeThumbColor: AppColors.primary,
          onChanged: (v) => _run(() => updateCycle(ref, showChip: v)),
        ),
        TextButton(
          onPressed: () => _run(() => updateCycle(ref, mode: 'paused')),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text('Pause — no period right now',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary)),
          ),
        ),
        _eraseButton(),
      ],
    );
  }

  /// Sin fecha registrada (eligió "Not sure"): no se estima nada. Vista mínima
  /// con la estación si la hubiera (winter registrado) y las acciones.
  Widget _trackingNoDate(BuildContext context, CycleView view) {
    final copy = view.season == null ? null : _seasonCopy[view.season!.key];
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        const Text('MY CYCLE', style: AppTypography.sectionLabel),
        const SizedBox(height: 10),
        Text('Your inner season.', style: _serif(context)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF221833), Color(0xFF2E2144)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: copy == null
              ? const Text(
                  'No signal to read right now — and nothing to catch up on. '
                  "Whenever you log your period, I'm here.",
                  style: TextStyle(
                      fontSize: 13, height: 1.6, color: Color(0xFFE9DFF2)),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${copy.$1}  ${copy.$2}',
                        style: const TextStyle(
                          fontFamily: AppTypography.serif,
                          fontStyle: FontStyle.italic,
                          fontSize: 17,
                          color: Color(0xFFF3EAF8),
                        )),
                    const SizedBox(height: 6),
                    Text(copy.$3,
                        style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.55,
                            color: Color(0xFFB9A8CC))),
                    if (view.season!.estimated) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'An estimate, never a verdict — your body has the '
                        'final word.',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF8E7BA6)),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 14),
        _primary('My period started today',
            () => _run(() => logPeriodStart(ref))),
        const SizedBox(height: 26),
        const Text('SETTINGS', style: AppTypography.sectionLabel),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show the season chip on Home',
              style: TextStyle(fontSize: 13.5)),
          value: view.showChip,
          activeThumbColor: AppColors.primary,
          onChanged: (v) => _run(() => updateCycle(ref, showChip: v)),
        ),
        TextButton(
          onPressed: () => _run(() => updateCycle(ref, mode: 'paused')),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text('Pause — no period right now',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary)),
          ),
        ),
        _eraseButton(),
      ],
    );
  }

  // --- piezas de la vista rica -------------------------------------------------
  String _regularityLabel(String r) => switch (r) {
        'regular' => 'Regular',
        'irregular' => 'Irregular',
        _ => 'Not sure',
      };

  String _phaseMessage(CyclePhase p) => switch (p) {
        CyclePhase.menstrual =>
          'Your body is asking for rest. Nothing to prove today.',
        CyclePhase.follicular =>
          'Energy often returns little by little now. No rush.',
        CyclePhase.ovulation =>
          'You may feel brighter these days. Enjoy it your way.',
        CyclePhase.luteal =>
          'Softer days may be near, so Aura eases the pace.',
      };

  Widget _outlinePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary)),
    );
  }

  Widget _legend() {
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      runSpacing: 8,
      children: [
        item(CyclePhase.menstrual.color, 'Menstrual'),
        item(CyclePhase.follicular.color, 'Follicular'),
        item(CyclePhase.ovulation.color, 'Ovulation'),
        item(CyclePhase.luteal.color, 'Luteal'),
      ],
    );
  }

  Widget _phaseMessageCard(CyclePhase phase) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0820), Color(0xFF4A0828)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _phaseMessage(phase),
              style: TextStyle(
                fontFamily: AppTypography.serif,
                fontStyle: FontStyle.italic,
                fontSize: 14,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _auraAdaptsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HOW AURA ADAPTS YOUR MICRO-HABITS',
              style: AppTypography.sectionLabel),
          const SizedBox(height: 8),
          Text.rich(TextSpan(children: [
            const TextSpan(
              text: 'Aura keeps it gentle — one small thing, or a full rest '
                  'day. ',
              style: TextStyle(
                  fontSize: 13.5, height: 1.5, color: AppColors.textPrimary),
            ),
            TextSpan(
              text: 'Never a demand.',
              style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
          ])),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color tint,
    required Color iconColor,
    required String title,
    required String pill,
    required Color pillColor,
    required Color pillBg,
    required String detail,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: tint, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                color: pillBg, borderRadius: BorderRadius.circular(50)),
            child: Text(pill,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: pillColor)),
          ),
          const SizedBox(height: 10),
          Text(detail,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _fertilityCard(({String level, String detail}) fert) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: const Color(0xFFF0EAFB),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.spa_outlined,
              size: 20, color: Color(0xFF6A3FA0)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fertility Window',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(fert.detail,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(50)),
          child: Text('✦ ${fert.level}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ),
      ]),
    );
  }

  Widget _statTile(String value, String label, IconData icon, Color tint) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: tint, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // --- paused · posparto/lactancia ------------------------------------------
  Widget _paused(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        const Text('MY CYCLE', style: AppTypography.sectionLabel),
        const SizedBox(height: 10),
        Text('A valid season of its own.', style: _serif(context)),
        const SizedBox(height: 6),
        const Text(
          "No period right now — postpartum, breastfeeding, or simply your "
          "body's moment. Nothing to track, nothing to catch up on. Whenever "
          "it returns, I'm here.",
          style: TextStyle(
              fontSize: 12.5, height: 1.6, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 22),
        _primary('My period came back',
            () => _run(() => updateCycle(ref, mode: 'tracking'))),
        _eraseButton(),
      ],
    );
  }

  // --- off · prefirió no compartir --------------------------------------------
  Widget _off(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        const Text('MY CYCLE', style: AppTypography.sectionLabel),
        const SizedBox(height: 10),
        Text('Nothing shared, nothing stored.', style: _serif(context)),
        const SizedBox(height: 6),
        const Text(
          'You chose not to share your cycle — only that choice is saved. '
          'If you ever change your mind, this door stays open.',
          style: TextStyle(
              fontSize: 12.5, height: 1.6, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 22),
        _primary('I changed my mind', () => setState(() => _settingUp = true)),
        _eraseButton(),
      ],
    );
  }

  // --- piezas -------------------------------------------------------------------
  TextStyle _serif(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontSize: 20,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          );

  Widget _door(String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFCE3EC) : AppColors.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color:
                  selected ? AppColors.primary : AppColors.textPrimary,
            )),
      ),
    );
  }

  Widget _primary(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF8E2C8E)]),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: _busy ? null : onTap,
            child: Center(
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('$label  ✦',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _eraseButton() {
    return TextButton(
      onPressed: _busy
          ? null
          : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Erase all my cycle data?'),
                  content: const Text(
                      'Everything about your cycle is deleted immediately '
                      'and completely. There is no trace left.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep it'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Erase everything',
                          style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await _run(() => deleteCycleData(ref));
              }
            },
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Text('Erase all my cycle data',
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary)),
      ),
    );
  }
}

/// Rueda del ciclo (mockup): 28 puntos coloreados por fase, el día actual
/// marcado con una insignia oscura, y en el centro "Cycle Day N / 28 · FASE".
class _CycleWheel extends StatelessWidget {
  const _CycleWheel({required this.cycleDay});

  final int cycleDay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(double.infinity, 250),
            painter: _CycleWheelPainter(cycleDay: cycleDay),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Cycle Day',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text.rich(TextSpan(children: [
                TextSpan(
                    text: '$cycleDay',
                    style: const TextStyle(
                        fontFamily: AppTypography.serif,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                TextSpan(
                    text: ' /${CycleEstimate.cycleLength}',
                    style: const TextStyle(
                        fontSize: 18, color: AppColors.textSecondary)),
              ])),
              const SizedBox(height: 2),
              Text(
                CycleEstimate.phaseOf(cycleDay).name.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CycleWheelPainter extends CustomPainter {
  _CycleWheelPainter({required this.cycleDay});

  final int cycleDay;

  static const int _total = CycleEstimate.cycleLength;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 24;

    // Un punto por día, coloreado por su fase (tenue salvo el día de hoy).
    for (var day = 1; day <= _total; day++) {
      final angle = -math.pi / 2 + (day - 1) / _total * 2 * math.pi;
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final color = CycleEstimate.phaseOf(day).color;
      final isCurrent = day == cycleDay;
      canvas.drawCircle(
        pos,
        isCurrent ? 6.5 : 4.5,
        Paint()..color = color.withValues(alpha: isCurrent ? 1 : 0.5),
      );
    }

    // Etiquetas de referencia (1, 7, 14, 21, 28) por fuera del anillo.
    for (final label in const [1, 7, 14, 21, 28]) {
      final angle = -math.pi / 2 + (label - 1) / _total * 2 * math.pi;
      final pos =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius + 18);
      _label(canvas, '$label', pos, const Color(0xFF9A93A3), 11);
    }

    // Insignia del día de hoy: círculo oscuro con el número.
    final ang = -math.pi / 2 + (cycleDay - 1) / _total * 2 * math.pi;
    final badge = center + Offset(math.cos(ang), math.sin(ang)) * radius;
    canvas.drawCircle(badge, 15, Paint()..color = const Color(0xFF2A1830));
    _label(canvas, '$cycleDay', badge, Colors.white, 13, bold: true);
  }

  void _label(Canvas canvas, String s, Offset at, Color color, double size,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_CycleWheelPainter oldDelegate) =>
      oldDelegate.cycleDay != cycleDay;
}

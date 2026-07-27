import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
  Widget _tracking(BuildContext context, CycleView view) {
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

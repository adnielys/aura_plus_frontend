import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/section_hero.dart';
import '../../../../shared/widgets/soft_primary_button.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/circle_provider.dart';

/// Mi círculo (Bloque 4 · mockup aprobado S1–S3): hasta 3 personas de
/// confianza ven UN resumen semanal agregado — jamás sus palabras, jamás su
/// día a día. Espejo transparente, revocación silenciosa, pausa de un toque.
class CircleScreen extends ConsumerStatefulWidget {
  const CircleScreen({super.key, this.origin = AppRoutes.support});

  /// A dónde volver al salir: el tab Care por defecto; Profile si se entró
  /// desde ahí. Evita que "atrás" caiga siempre en Profile o salga de la app.
  final String origin;

  @override
  ConsumerState<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends ConsumerState<CircleScreen> {
  final _emailController = TextEditingController();
  bool _inviting = false; // S2 visible
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.invalidate(circleProvider);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Ejecuta una acción del círculo. Devuelve true si salió bien. Ante error
  /// avisa sereno (sin regañar) en vez de tragarlo: el fallo silencioso hacía
  /// creer que la invitación entró cuando no.
  Future<bool> _run(Future<void> Function() action) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await action();
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text("That didn't go through. No rush — try again in a moment."),
          ));
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "Remove" es terminal (el enlace muere al instante): pide confirmación
  /// serena. Cancelar una invitación aún no aceptada no la pide (bajo riesgo).
  Future<void> _confirmRemove(CircleMember member) async {
    if (member.status != 'accepted') {
      await _run(() => revokeCircleMember(ref, member.id));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from your circle?'),
        content: Text(
          '${member.email} will stop seeing your weekly summary. '
          'The link ends right away — quietly, without telling them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() => revokeCircleMember(ref, member.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final circle = ref.watch(circleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: circle.when(
        loading: () =>
            const SafeArea(child: Center(child: CircularProgressIndicator())),
        error: (_, _) => SafeArea(
          child: Center(
            child: TextButton(
              onPressed: () => ref.invalidate(circleProvider),
              child: const Text('Try again'),
            ),
          ),
        ),
        data: (view) =>
            _inviting ? _invite(context, view) : _main(context, view),
      ),
    );
  }

  /// Vuelve atrás: hace pop si se entró con push (lo normal); si no, va al
  /// origen (tab Care). Así el atrás nunca cae en Profile ni sale de la app.
  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.origin);
    }
  }

  // --- S1 (vacío) + S3 (gestión): una sola pantalla con espejo ---------------
  Widget _main(BuildContext context, CircleView view) {
    final empty = view.members.isEmpty;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _header(context, empty),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        if (empty)
          const Text(
            'Choose up to 3 people you trust. Once a week, they see a small '
            'summary of what you BUILT — never your words, never your '
            'day-by-day.',
            style: TextStyle(
                fontSize: 12.5, height: 1.55, color: AppColors.textSecondary),
          ),
        // Más aire antes del bloque de cards: el mockup lo respira más abajo.
        const SizedBox(height: 40),
        if (!empty) ...[
          for (final member in view.members) _memberRow(member),
          const SizedBox(height: 14),
        ],
        _mirror(view),
        const SizedBox(height: 12),
        if (empty) _neverSee(),
        const SizedBox(height: 16),
        if (view.spotsLeft > 0 && !view.paused)
          _primary(
            empty
                ? 'Invite someone I trust'
                : 'Invite (${view.spotsLeft} ${view.spotsLeft == 1 ? 'spot' : 'spots'} left)',
            () => setState(() => _inviting = true),
          ),
        if (!empty || view.paused) ...[
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pause my circle',
                style: TextStyle(fontSize: 13.5)),
            subtitle: const Text(
              'One tap. They just see a closed page — nobody is removed, '
              'nobody is told.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            value: view.paused,
            activeThumbColor: AppColors.careAccent,
            onChanged: (v) => _run(() => setCirclePaused(ref, v)),
          ),
        ],
        if (empty)
          // Ancho completo: en una Column alineada a start el texto se queda
          // con su ancho natural y textAlign.center no lo centraría en la
          // pantalla — quedaría pegado a la izquierda, no bajo el botón.
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                'Nothing is shared until someone accepts your invite.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ),
        Center(
          child: TextButton(
            onPressed: _goBack,
            child: const Text('← Back',
                style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary)),
          ),
        ),
            ],
          ),
        ),
      ],
    );
  }

  /// Cabecera ESTÁNDAR ([SectionHero]): misma altura que Care y Profile, para
  /// que las pantallas de sección se lean como un sistema. Titular serif a dos
  /// líneas en charcoal (no carmesí — es una pantalla serena).
  Widget _header(BuildContext context, bool empty) {
    final title = Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 30,
          height: 1.12,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        );
    return SectionHero(
      asset: 'assets/images/care/circle_hero.png',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chevron y etiqueta en la MISMA línea: flecha primero, luego el
            // rótulo de sección.
            Row(
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.back,
                      size: 22, color: AppColors.textPrimary),
                  tooltip: 'Care',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: _goBack,
                ),
                const SizedBox(width: 10),
                const Text('MY CIRCLE', style: AppTypography.sectionLabel),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: FractionallySizedBox(
                widthFactor: 0.82,
                alignment: Alignment.centerLeft,
                // Dos tonos: primera línea gris, segunda carmesí.
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: empty ? 'Share your light —\n' : 'Your people,\n',
                    ),
                    TextSpan(
                      text: empty ? 'only if you want.' : 'your rules.',
                      style: title.copyWith(color: AppColors.primary),
                    ),
                  ]),
                  style: title,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- S2 · invitar (consentimiento informado) --------------------------------
  Widget _invite(BuildContext context, CircleView view) {
    return SafeArea(
      child: ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        const Text('INVITE TO MY CIRCLE', style: AppTypography.sectionLabel),
        const SizedBox(height: 10),
        Text('Someone who walks with you.', style: _serif(context)),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'their.email@example.com',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "They'll get an email with a private link — no app, no account "
          'needed. The link shows only the weekly summary and renews every '
          'time they open it.',
          style: TextStyle(
              fontSize: 12, height: 1.55, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            '🔒 You can remove them whenever you want — the link dies that '
            'same second, without telling them anything. Removing someone is '
            'yours alone; nobody can pause or undo it but you.',
            style: TextStyle(
                fontSize: 11.5, height: 1.55, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 20),
        _primary('Send invite', () async {
          final email = _emailController.text.trim();
          if (email.isEmpty || !email.contains('@')) return;
          final ok = await _run(() => inviteCircleMember(ref, email));
          // Solo si entró de verdad: si no, el email se queda para reintentar.
          if (ok && mounted) {
            _emailController.clear();
            setState(() => _inviting = false);
          }
        }),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _inviting = false),
            child: const Text('← Back',
                style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary)),
          ),
        ),
      ],
    ),
    );
  }

  // --- piezas ------------------------------------------------------------------
  TextStyle _serif(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontSize: 20,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          );

  /// Card del patrón CARE: color de fondo, hojas al ~22% ancladas a la derecha
  /// y borde por fuera del recorte. El texto va encima y sigue legible.
  Widget _leafCard({
    required Color background,
    required Color border,
    required String leafAsset,
    required Widget child,
  }) {
    return SizedBox(
      // Ancho completo: dentro de un Column los cards se encogerían al ancho de
      // su texto más largo (y verde y rosa quedarían distintos). Forzarlo los
      // deja iguales y a todo el ancho, como el maquetado.
      width: double.infinity,
      child: DecoratedBox(
      // El borde va en PRIMER PLANO: si se pinta detrás, el relleno del card
      // lo tapa y no se ve. Encima queda como un contorno fino y nítido.
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: background)),
            Positioned.fill(
              child: Image.asset(
                leafAsset,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                opacity: const AlwaysStoppedAnimation(0.22),
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ),
      ),
      ),
    );
  }

  Widget _memberRow(CircleMember member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFEDF6F4),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.email.isEmpty ? '?' : member.email[0].toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.careAccent),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
                Text(
                  member.status == 'accepted'
                      ? 'In your circle'
                      : "Invited · hasn't opened it yet",
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _busy ? null : () => _confirmRemove(member),
            child: Text(
              member.status == 'accepted' ? 'Remove' : 'Cancel',
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mirror(CircleView view) {
    final v = view.sharedView;
    return _leafCard(
      background: const Color(0xFFEDF6F4),
      border: const Color(0xFFCDE4DF),
      leafAsset: 'assets/images/care/card1.png',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            view.members.isEmpty
                ? 'THEY WOULD SEE (EXACTLY THIS, ONCE A WEEK)'
                : 'WHAT THEY SEE THIS WEEK — YOUR MIRROR',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.careAccent,
            ),
          ),
          const SizedBox(height: 7),
          if (v.quiet)
            Text('· ${v.note}', style: _mirrorText())
          else ...[
            if (v.presence != null)
              Text('· ${v.presence}', style: _mirrorText()),
            if (v.mostPresentArea != null)
              Text('· The area that held you most: ${v.mostPresentArea}',
                  style: _mirrorText()),
            Text('· “${v.note}”', style: _mirrorText()),
          ],
        ],
      ),
    );
  }

  TextStyle _mirrorText() => const TextStyle(
      fontSize: 11.5, height: 1.6, color: Color(0xFF35544F));

  Widget _neverSee() {
    return _leafCard(
      background: const Color(0xFFFDF0F3),
      border: AppColors.border,
      leafAsset: 'assets/images/care/card2.png',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THEY WILL NEVER SEE',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 7),
          Text(
            '· Your reflections or any words you write\n'
            '· How you arrived each day (your check-ins)\n'
            '· Anything live — no real-time, no alerts\n'
            '· A way to reply: Aura has no inbox for them',
            style: TextStyle(fontSize: 11.5, height: 1.6, color: Color(0xFF6B4552)),
          ),
        ],
      ),
    );
  }

  Widget _primary(String label, VoidCallback onTap) {
    return SoftPrimaryButton(
      label: label,
      onPressed: onTap,
      isLoading: _busy,
    );
  }
}

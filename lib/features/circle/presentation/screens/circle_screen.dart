import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/circle_provider.dart';

/// Mi círculo (Bloque 4 · mockup aprobado S1–S3): hasta 3 personas de
/// confianza ven UN resumen semanal agregado — jamás sus palabras, jamás su
/// día a día. Espejo transparente, revocación silenciosa, pausa de un toque.
class CircleScreen extends ConsumerStatefulWidget {
  const CircleScreen({super.key});

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

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      // El siguiente gesto reintenta: el círculo jamás regaña.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final circle = ref.watch(circleProvider);

    return Scaffold(
      body: SafeArea(
        child: circle.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(circleProvider),
              child: const Text('Try again'),
            ),
          ),
          data: (view) =>
              _inviting ? _invite(context, view) : _main(context, view),
        ),
      ),
    );
  }

  // --- S1 (vacío) + S3 (gestión): una sola pantalla con espejo ---------------
  Widget _main(BuildContext context, CircleView view) {
    final empty = view.members.isEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        const Text('MY CIRCLE', style: AppTypography.sectionLabel),
        const SizedBox(height: 10),
        Text(
          empty ? 'Share your light — only if you want.' : 'Your people, your rules.',
          style: _serif(context),
        ),
        if (empty) ...[
          const SizedBox(height: 6),
          const Text(
            'Choose up to 3 people you trust. Once a week, they see a small '
            'summary of what you BUILT — never your words, never your '
            'day-by-day.',
            style: TextStyle(
                fontSize: 12.5, height: 1.55, color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 16),
        if (!empty) ...[
          for (final member in view.members) _memberRow(member),
          const SizedBox(height: 14),
        ],
        _mirror(view),
        const SizedBox(height: 12),
        if (empty) _neverSee(),
        const SizedBox(height: 14),
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
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Nothing is shared until someone accepts your invite.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        Center(
          child: TextButton(
            onPressed: () => context.go(AppRoutes.profile),
            child: const Text('← Back',
                style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary)),
          ),
        ),
      ],
    );
  }

  // --- S2 · invitar (consentimiento informado) --------------------------------
  Widget _invite(BuildContext context, CircleView view) {
    return ListView(
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
          await _run(() => inviteCircleMember(ref, email));
          if (mounted) {
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
            onPressed: _busy
                ? null
                : () => _run(() => revokeCircleMember(ref, member.id)),
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
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF6F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCDE4DF)),
      ),
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
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF0F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
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
}

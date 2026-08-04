import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/section_hero.dart';
import '../providers/care_providers.dart';
import '../widgets/care_widgets.dart';

/// Flujo care (A2/A4/A5/A6): UNA pantalla gobernada por el estado del
/// servidor. Sin pasos guardados en el cliente: lo que diga
/// `careCurrentReferralProvider` es la vista — así el estado nunca miente.
class CareScreen extends ConsumerStatefulWidget {
  const CareScreen({super.key});

  @override
  ConsumerState<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends ConsumerState<CareScreen> {
  @override
  void initState() {
    super.initState();
    // Al entrar SIEMPRE se reconsulta (polling suave — jamás push): si el
    // profesional respondió, se ve aquí, en el momento en que ella lo abre.
    Future.microtask(() {
      if (mounted) ref.invalidate(careCurrentReferralProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final referral = ref.watch(careCurrentReferralProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: referral.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.careAccent),
          ),
          error: (_, _) => _ErrorRetry(
            onRetry: () => ref.invalidate(careCurrentReferralProvider),
          ),
          data: (current) => switch (resolveCareView(current)) {
            // D1: directorio libre · D3: mismo directorio con la petición
            // pendiente (badge 📤, resto en reposo). El estado de la solicitud
            // (D4) vive en su propia ruta: /care/request.
            CareView.directory => const _DirectoryView(pending: null),
            CareView.sent => _DirectoryView(pending: current),
            CareView.responseAccepted => _ResponseAcceptedView(referral: current!),
            CareView.responseDeclined => _ResponseDeclinedView(referral: current!),
            CareView.episode => _EpisodeView(referral: current!),
          },
        ),
      ),
    );
  }
}

// ── D1/D2/D3 · Directorio con buscador (y modo petición pendiente) ───────────
class _DirectoryView extends ConsumerStatefulWidget {
  const _DirectoryView({required this.pending});

  /// Petición pendiente (D3): su card lleva 📤 y el resto descansa con 🔒.
  final CareReferral? pending;

  @override
  ConsumerState<_DirectoryView> createState() => _DirectoryViewState();
}

class _DirectoryViewState extends ConsumerState<_DirectoryView> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _tier; // null = Todas

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _locked => widget.pending != null;

  void _showOneAtATime() {
    final name = widget.pending?.providerName == null
        ? 'esa persona'
        : shortProviderName(widget.pending!.providerName!);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          'One person at a time: your request to $name is still in her hands.',
        ),
      ));
  }

  String get _pendingName => widget.pending?.providerName == null
      ? 'this person'
      : shortProviderName(widget.pending!.providerName!);

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.support);
    }
  }

  @override
  Widget build(BuildContext context) {
    final directory = ref.watch(careDirectoryProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _hero(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_locked) ...[
                CareLockBanner(name: _pendingName),
                const SizedBox(height: 10),
              ],
              CareSearchField(
                controller: _searchController,
                enabled: !_locked,
                onChanged: (value) => setState(() => _query = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
              const SizedBox(height: 10),
              CareTierChips(
                selected: _tier,
                enabled: !_locked,
                onSelected: (tier) => setState(() => _tier = tier),
              ),
              const SizedBox(height: 12),
              const Text(
                'Specialists for you',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ...directory.when(
                loading: () => const [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child:
                          CircularProgressIndicator(color: AppColors.careAccent),
                    ),
                  ),
                ],
                error: (_, _) => [
                  _ErrorRetry(
                      onRetry: () => ref.invalidate(careDirectoryProvider)),
                ],
                data: (providers) => _directoryList(context, providers),
              ),
              const SizedBox(height: 12),
              if (_locked)
                CarePrimaryButton(
                  label: 'View my request',
                  crimson: true,
                  onPressed: () => context.push(AppRoutes.careRequest),
                )
              else
                const _CareFooterNote(),
            ],
          ),
        ),
      ],
    );
  }

  /// Hero ilustrado con el titular carmesí. Usa la cabecera ESTÁNDAR
  /// ([SectionHero]): misma altura que My circle y Profile.
  Widget _hero(BuildContext context) {
    final title = Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 30,
          height: 1.1,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        );
    return SectionHero(
      asset: 'assets/images/care/support_hero.png',
      child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chevron y etiqueta en la MISMA línea: flecha primero, luego
                  // el rótulo de sección.
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
                      const Text('CARE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: AppColors.textPrimary,
                          )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(
                          widthFactor: 0.72,
                          alignment: Alignment.centerLeft,
                          // Dos tonos: primera línea gris, segunda carmesí.
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                text: 'Find someone\n',
                                style:
                                    title.copyWith(color: AppColors.textPrimary),
                              ),
                              const TextSpan(text: 'who understands'),
                            ]),
                            style: title,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const FractionallySizedBox(
                          widthFactor: 0.66,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Compassionate specialists, here for you — '
                            'when and how you need them.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _directoryList(
      BuildContext context, List<CareProviderInfo> providers) {
    // En modo pendiente no se filtra: el directorio descansa tal cual.
    final visible = _locked
        ? providers
        : filterProviders(providers, query: _query, tier: _tier);
    final support = visible.where((p) => p.tier == 'support').toList();
    final clinical = visible.where((p) => p.tier == 'clinical').toList();
    return [
      if (support.isNotEmpty) ...[
        const CareTierLabel(tier: 'support'),
        const SizedBox(height: 8),
        for (final provider in support) _specialistCard(context, provider),
      ],
      if (clinical.isNotEmpty) ...[
        const SizedBox(height: 10),
        const CareTierLabel(tier: 'clinical'),
        const SizedBox(height: 8),
        for (final provider in clinical) _specialistCard(context, provider),
      ],
      if (visible.isEmpty && _query.trim().isNotEmpty)
        // Nunca un vacío sin salida (D2).
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            "I couldn't find anyone like that.\n"
            'Try fewer letters — or clear the search and browse by level.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12.5, height: 1.6, color: AppColors.textSecondary),
          ),
        )
      else if (visible.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Text(
            'The directory is taking shape. Come back soon — no rush.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
    ];
  }

  Widget _specialistCard(BuildContext context, CareProviderInfo provider) {
    final isRequested = _locked && provider.id == widget.pending?.providerId;
    final isResting = _locked && !isRequested;
    final clinical = provider.tier == 'clinical';
    final accent = clinical ? AppColors.clinicalAccent : AppColors.careAccent;
    final tint = clinical ? AppColors.clinicalSurface : AppColors.careSurface;
    final specialty = provider.specialties.isNotEmpty
        ? provider.specialties.take(2).join(' · ')
        : (clinical ? 'Clinical support' : 'Companion support');
    final languages = provider.languages.map((l) => l.toUpperCase()).join(' / ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: isResting ? 0.5 : 1,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isRequested
                ? () => context.push(AppRoutes.careRequest)
                : isResting
                    ? _showOneAtATime
                    : () =>
                        context.push(AppRoutes.careConsent, extra: provider),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        isRequested ? AppColors.careBorder : AppColors.border),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      provider.fullName.isEmpty
                          ? '·'
                          : provider.fullName.characters.first.toUpperCase(),
                      style: TextStyle(
                        fontFamily: AppTypography.serif,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.fullName,
                          style: const TextStyle(
                            fontFamily: AppTypography.serif,
                            fontSize: 16,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                                clinical
                                    ? Icons.verified_user_outlined
                                    : Icons.spa_outlined,
                                size: 14,
                                color: accent),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                specialty,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: accent),
                              ),
                            ),
                          ],
                        ),
                        if (languages.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(languages,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                        const SizedBox(height: 7),
                        _statusChip(provider),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isRequested)
                    const CareSentBadge()
                  else if (isResting)
                    const Icon(CupertinoIcons.lock,
                        size: 16, color: Color(0xFFB9AFC2))
                  else
                    // Mismo chevron iOS que Profile.
                    const Icon(CupertinoIcons.chevron_right,
                        size: 20, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Chip de verificación (dot + texto), al estilo "disponibilidad" del target.
  Widget _statusChip(CareProviderInfo provider) {
    final text =
        provider.licenseVerified ? 'Licensed & verified' : 'Verified';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.careSurface,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: AppColors.careAccent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.careAccent)),
        ],
      ),
    );
  }
}

/// Footer del directorio con el estilo del mensaje de Aura: fondo oscuro con
/// resplandor, corazón en círculo claro, hojas al fondo y texto serif itálica.
class _CareFooterNote extends StatelessWidget {
  const _CareFooterNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0820), Color(0xFF4A0828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/care/card2.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              opacity: const AlwaysStoppedAnimation(0.14),
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: AppColors.roseTint, shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_border_rounded,
                      size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You deserve care that feels right.',
                        style: TextStyle(
                          fontFamily: AppTypography.serif,
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "We're here to help you find it.",
                        style: TextStyle(
                          fontFamily: AppTypography.serif,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                          height: 1.35,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── A5 · Respuesta recibida: aceptó ─────────────────────────────────────────
class _ResponseAcceptedView extends ConsumerStatefulWidget {
  const _ResponseAcceptedView({required this.referral});

  final CareReferral referral;

  @override
  ConsumerState<_ResponseAcceptedView> createState() =>
      _ResponseAcceptedViewState();
}

class _ResponseAcceptedViewState extends ConsumerState<_ResponseAcceptedView> {
  bool _saving = false;

  /// "Ya me puse en contacto": SU máquina avanza offered→accepted→connected.
  /// Lo marca ELLA — el sistema jamás la conecta solo.
  Future<void> _markContacted() async {
    setState(() => _saving = true);
    try {
      await advanceCareReferral(ref,
          referralId: widget.referral.id, status: 'accepted');
      await advanceCareReferral(ref,
          referralId: widget.referral.id, status: 'connected');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save it. Try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final referral = widget.referral;
    final fullName = referral.providerName ?? 'Your support person';
    final name = shortProviderName(fullName);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        const CareBackRow(),
        const SizedBox(height: 6),
        const Text('YOUR SUPPORT EPISODE', style: AppTypography.sectionLabel),
        const SizedBox(height: 10),
        CareProviderCard(
          name: fullName,
          meta: 'She accepted your request ✦',
          metaColor: AppColors.careAccent,
          tier: 'support',
        ),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: '$name said yes. ', style: _serif(context)),
            TextSpan(
              text: "Whenever you're ready.",
              style: _serifAccent(context),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        CareContactCard(
          contact: referral.providerContact,
          note: 'Write to her whenever it suits you. '
              'No rush: you already took the first step.',
        ),
        const SizedBox(height: 14),
        CarePrimaryButton(
          label: 'I got in touch',
          outlined: true,
          busy: _saving,
          onPressed: _markContacted,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text(
              'Back to my space',
              style: TextStyle(
                  fontWeight: FontWeight.w400, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

// ── A5b · Respuesta recibida: no puede ahora ─────────────────────────────────
class _ResponseDeclinedView extends ConsumerStatefulWidget {
  const _ResponseDeclinedView({required this.referral});

  final CareReferral referral;

  @override
  ConsumerState<_ResponseDeclinedView> createState() =>
      _ResponseDeclinedViewState();
}

class _ResponseDeclinedViewState extends ConsumerState<_ResponseDeclinedView> {
  bool _saving = false;

  /// "Ver otras personas": cierra esta petición (declined, terminal) y el
  /// mismo estado del servidor la devuelve al directorio.
  Future<void> _backToDirectory() async {
    setState(() => _saving = true);
    try {
      await advanceCareReferral(ref,
          referralId: widget.referral.id, status: 'declined');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save it. Try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.referral.providerName == null
        ? 'Esa persona'
        : shortProviderName(widget.referral.providerName!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(top: 12),
              child: CareBackRow(),
            ),
          ),
          const Spacer(),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: "$name can't walk with you\nright now. ",
                  style: _serif(context)),
              TextSpan(
                text: 'It says nothing about you.',
                style: _serifAccent(context),
              ),
            ]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'There are more people in the directory, whenever you want. '
            'No rush — your space is still here.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13.5, height: 1.55, color: AppColors.textSecondary),
          ),
          const Spacer(),
          CarePrimaryButton(
            label: 'See other people',
            busy: _saving,
            onPressed: _backToDirectory,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text(
                'Back to my space',
                style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── A6 · Episodio en curso + cierre (B-3) ────────────────────────────────────
class _EpisodeView extends ConsumerStatefulWidget {
  const _EpisodeView({required this.referral});

  final CareReferral referral;

  @override
  ConsumerState<_EpisodeView> createState() => _EpisodeViewState();
}

class _EpisodeViewState extends ConsumerState<_EpisodeView> {
  String? _outcome; // voluntario: null = no decir nada, con idéntica dignidad
  bool _saving = false;

  Future<void> _closeChapter() async {
    // Capturado ANTES de los await: el invalidate reconstruye CareScreen y
    // este subárbol puede desmontarse con el diálogo aún abierto — la vuelta
    // al perfil no depende de seguir montados.
    final router = GoRouter.of(context);
    setState(() => _saving = true);
    String? closingMessage;
    try {
      closingMessage = await advanceCareReferral(
        ref,
        referralId: widget.referral.id,
        status: 'closed',
        closeOutcome: _outcome,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't close it. Try again.")),
        );
      }
      if (mounted) setState(() => _saving = false);
      return;
    }
    // Mensaje CARE_CLOSE del servidor (neutral al resultado), y de vuelta al
    // perfil: la fila CUIDADO regresa a su estado base. Sin confeti (no es
    // un logro gamificado, es una despedida serena). El diálogo vive en el
    // navigator raíz: sobrevive aunque este subárbol se reconstruya.
    final message = closingMessage;
    if (message != null && mounted) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.serif,
                    fontStyle: FontStyle.italic,
                    fontSize: 17,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Thank you',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.careAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    router.go(AppRoutes.support);
  }

  @override
  Widget build(BuildContext context) {
    final referral = widget.referral;
    final name = referral.providerName ?? 'Your support person';
    final connected = referral.status == 'connected';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        const CareBackRow(),
        const SizedBox(height: 6),
        const Text('YOUR SUPPORT EPISODE', style: AppTypography.sectionLabel),
        const SizedBox(height: 10),
        CareProviderCard(
          name: name,
          meta: connected ? 'Connected' : 'By your side',
          tier: 'support',
        ),
        const SizedBox(height: 12),
        // Pasos: SOLO lo andado — nunca cuánto falta (GUARD_TONE del care).
        CareSteps(connected: connected),
        const SizedBox(height: 12),
        CareContactCard(
          contact: referral.providerContact,
          note: 'Her contact stays here, always at hand.',
        ),
        const SizedBox(height: 26),
        Text('Do you want to close this chapter?',
            style: _serif(context).copyWith(fontSize: 18)),
        const SizedBox(height: 6),
        const Text(
          'Only if you decide so. You can tell me how it went — or not. '
          'Both are okay.',
          style: TextStyle(
              fontSize: 12.5, height: 1.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label) in const [
              ('helped', 'It helped me'),
              ('not_for_me', "It wasn't for me"),
              ('prefer_not_say', "I'd rather not say"),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _outcome == value,
                onSelected: (selected) =>
                    setState(() => _outcome = selected ? value : null),
                selectedColor: AppColors.careSurface,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  color: _outcome == value
                      ? AppColors.careAccent
                      : AppColors.textPrimary,
                  fontWeight:
                      _outcome == value ? FontWeight.w700 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: _outcome == value
                      ? AppColors.careBorder
                      : AppColors.border,
                ),
                showCheckmark: false,
              ),
          ],
        ),
        const SizedBox(height: 14),
        CarePrimaryButton(
          label: 'Close this chapter',
          crimson: true,
          busy: _saving,
          onPressed: _closeChapter,
        ),
      ],
    );
  }
}

// ── comunes ──────────────────────────────────────────────────────────────────
// Tipografía del mockup: base serif w600 SIN itálica; el acento va en
// itálica carmesí (h2.serif i del maquetado).
TextStyle _serif(BuildContext context) =>
    Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.normal,
          color: AppColors.textPrimary,
        );

TextStyle _serifAccent(BuildContext context) => _serif(context).copyWith(
      fontStyle: FontStyle.italic,
      color: AppColors.primary,
    );

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Couldn't load. No rush.",
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Try again',
                style: TextStyle(color: AppColors.careAccent)),
          ),
        ],
      ),
    );
  }
}

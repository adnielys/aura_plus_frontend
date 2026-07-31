import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import 'cycle_closing_provider.dart';

/// El relato de un ciclo YA cerrado (`GET /constellation/{id}/story`).
///
/// El servidor lo regenera DETERMINISTA por ciclo y sin tocar rotaciones:
/// releerlo devuelve siempre el mismo texto (la memoria no se retoca).
typedef CycleStory = ({List<RetroLine> lines, String closing});

final cycleStoryProvider =
    FutureProvider.family<CycleStory, String>((ref, constellationId) async {
  final dio = ref.watch(dioProvider);
  final response =
      await dio.get<Object?>('/constellation/$constellationId/story');
  final body = unwrapEnvelope(response.data) as Map;
  final retro = body['retrospective'] as Map? ?? const {};
  return (
    lines: [
      for (final line in (retro['lines'] as List? ?? const []))
        (
          key: ((line as Map)['key'] as String?) ?? '',
          text: (line['text'] as String?) ?? '',
        ),
    ],
    closing: (retro['closing'] as String?) ?? '',
  );
});

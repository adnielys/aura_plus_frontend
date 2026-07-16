import '../../../../shared/domain/constellation.dart';

/// Ilustraciones de constelación (maquetado · constelaciones/): se asignan de
/// forma determinista por número de ciclo, rotando el set disponible.
const _images = [
  'assets/images/constellation/sagitario.png',
  'assets/images/constellation/tauro.png',
  'assets/images/constellation/serena.png',
];

extension ConstellationVisuals on Constellation {
  String get imageAsset => _images[(cycleNumber - 1) % _images.length];
}

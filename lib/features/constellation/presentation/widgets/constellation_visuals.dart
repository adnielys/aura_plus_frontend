import '../../../../shared/domain/constellation.dart';

/// Ilustraciones de constelación del DISEÑADOR (set completo jul 2026:
/// 12 zodiacales + 8 mitológicas, estilo rosa ilustrado, 1280w optimizadas):
/// se asignan de forma determinista por número de ciclo — zodíaco en orden y
/// después las mitológicas — alineadas 1:1 con _CYCLE_NAMES del backend.
/// NO reordenar: cambiaría cielos ya vividos.
const _images = [
  'assets/images/constellation/aries.jpg',
  'assets/images/constellation/tauro.jpg',
  'assets/images/constellation/geminis.jpg',
  'assets/images/constellation/cancer.jpg',
  'assets/images/constellation/leo.jpg',
  'assets/images/constellation/virgo.jpg',
  'assets/images/constellation/libra.jpg',
  'assets/images/constellation/escorpio.jpg',
  'assets/images/constellation/sagitario.jpg',
  'assets/images/constellation/capricornio.jpg',
  'assets/images/constellation/acuario.jpg',
  'assets/images/constellation/piscis.jpg',
  'assets/images/constellation/orion.jpg',
  'assets/images/constellation/andromeda.jpg',
  'assets/images/constellation/casiopea.jpg',
  'assets/images/constellation/perseo.jpg',
  'assets/images/constellation/pegaso.jpg',
  'assets/images/constellation/cisne.jpg',
  'assets/images/constellation/hercules.jpg',
  'assets/images/constellation/lyra.jpg',
];

extension ConstellationVisuals on Constellation {
  String get imageAsset => _images[(cycleNumber - 1) % _images.length];
}

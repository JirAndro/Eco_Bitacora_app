import 'package:eco_bitacora/models/registro_model.dart';

class MotorEcoalfabetizacion {
  static Map<String, dynamic> procesarInformeQuincenal(
    List<Registro> registros,
  ) {
    if (registros.isEmpty) {
      return {
        'hayDatos': false,
        'mensaje': 'Aún no hay datos suficientes en esta quincena.',
        'tip':
            'El primer paso para cuidar el medio ambiente es la observación. ¡Comienza a registrar!',
      };
    }

    // 1. Agrupar y sumar por Eje
    Map<String, double> totalesPorEje = {};
    for (var reg in registros) {
      totalesPorEje[reg.eje] = (totalesPorEje[reg.eje] ?? 0) + reg.cantidad;
    }

    // 2. Determinar el área de mayor impacto
    String ejePrincipal = totalesPorEje.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // 3. Diccionario de Ecoalfabetización (Reglas de Negocio)
    Map<String, String> consejosTecnicos = {
      'Agua':
          'Tu mayor registro quincenal fue en Agua. Recuerda revisar empaques en tu hogar y considerar la instalación de reductores de caudal en los grifos.',
      'Residuos':
          'Tus registros de Residuos son altos. Reduce el volumen separando la fracción orgánica para crear composta casera.',
      'Energía':
          'El consumo de Energía destaca esta quincena. Aprovecha la luz natural y desconecta los aparatos que no estén en uso continuo.',
    };

    return {
      'hayDatos': true,
      'eje_principal': ejePrincipal,
      'totales': totalesPorEje,
      'tip':
          consejosTecnicos[ejePrincipal] ??
          'Sigue monitoreando tu entorno para identificar áreas de mejora.',
    };
  }
}

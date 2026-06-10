class Registro {
  final int? id;
  final String uuid;
  final String fecha;
  final String timestamp;
  final String eje;
  final String categoria; // "Origen" (Ej: Supermercado)
  final String? subcategoria; // "Procesamiento" (Ej: Ultraprocesado)
  final double cantidad;
  final String observaciones;
  final double? latitud;
  final double? longitud;
  final int sincronizado;
  final String? fotoPath;

  Registro({
    this.id,
    required this.uuid,
    required this.fecha,
    required this.timestamp,
    required this.eje,
    required this.categoria,
    this.subcategoria,
    required this.cantidad,
    required this.observaciones,
    this.latitud,
    this.longitud,
    this.sincronizado = 0,
    this.fotoPath,
  });

  factory Registro.fromMap(Map<String, dynamic> map) {
    return Registro(
      id: map['id'],
      uuid: map['uuid'] ?? '',
      fecha: map['fecha'] ?? '',
      timestamp: map['timestamp'] ?? '',
      eje: map['eje'] ?? '',
      categoria: map['categoria'] ?? '',
      subcategoria: map['subcategoria'], // Nuevo
      cantidad: (map['cantidad'] as num).toDouble(),
      observaciones: map['observaciones'] ?? '',
      latitud: map['latitud'],
      longitud: map['longitud'],
      sincronizado: map['sincronizado'] ?? 0,
      fotoPath: map['fotoPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'fecha': fecha,
      'timestamp': timestamp,
      'eje': eje,
      'categoria': categoria,
      'subcategoria': subcategoria,
      'cantidad': cantidad,
      'observaciones': observaciones,
      'latitud': latitud,
      'longitud': longitud,
      'sincronizado': sincronizado,
      'fotoPath': fotoPath,
    };
  }
}

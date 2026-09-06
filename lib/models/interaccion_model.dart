class Interaccion {
  final String id;
  final String emisor;
  final String tipoEvento;
  final String? textoProcesado;
  final String? urlAudioReferencia;
  final bool procesadoPorIa;
  final int? duracionSegundos;

  Interaccion({
    required this.id,
    required this.emisor,
    required this.tipoEvento,
    this.textoProcesado,
    this.urlAudioReferencia,
    required this.procesadoPorIa,
    this.duracionSegundos,
  });

  // Este método traduce el JSON crudo de Supabase a variables seguras en Dart
  factory Interaccion.fromJson(Map<String, dynamic> json) {
    // Extraemos la "caja flexible" JSONB del payload
    final metadata = json['metadata_payload'] ?? {};
    
    return Interaccion(
      id: json['id']?.toString() ?? '',
      emisor: json['emisor'] ?? '',
      tipoEvento: json['tipo_evento'] ?? '',
      // Mapeo estricto del metadata_payload
      textoProcesado: metadata['texto_procesado'],
      urlAudioReferencia: metadata['url_audio_referencia'],
      procesadoPorIa: metadata['procesado_por_ia'] ?? false,
      duracionSegundos: metadata['duracion_segundos'],
    );
  }
}
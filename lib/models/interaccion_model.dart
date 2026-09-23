// Modelo que representa una fila de la tabla `historial_interacciones` (V2).
//
// Contratos de backend que este modelo respeta:
//   - Columna `metadata_payload` (JSONB): parsea `texto_procesado`,
//     `url_audio_referencia`, `procesado_por_ia` y `duracion_segundos`.
//   - Campos nativos V2: `estado_reproduccion` y `prioridad`.
//
// Todos los campos opcionales tienen valores por defecto seguros para que
// ninguna excepción de tipo sea lanzada si el backend omite un campo.

// ─────────────────────────────────────────────────────────────────────────────
// Sub-modelo: MetadataPayload
// Mapea la columna JSONB `metadata_payload` con tipos seguros.
// ─────────────────────────────────────────────────────────────────────────────
class MetadataPayload {
  /// Transcripción del mensaje o instrucción. Obligatorio lógicamente,
  /// pero nullable en caso de que el backend lo omita por un error.
  final String? textoProcesado;

  /// URL firmada hacia Supabase Storage. Null si el evento no tiene audio.
  final String? urlAudioReferencia;

  /// Indica si el evento pasó por el flujo de Claude 3 Haiku.
  final bool procesadoPorIa;

  /// Duración del audio en segundos. Opcional; viene solo en eventos de audio.
  final int? duracionSegundos;

  const MetadataPayload({
    this.textoProcesado,
    this.urlAudioReferencia,
    required this.procesadoPorIa,
    this.duracionSegundos,
  });

  /// Construye un [MetadataPayload] desde el mapa JSONB de Supabase.
  /// Acepta tanto `Map<String, dynamic>` como `null` (si la fila no tiene
  /// payload aún).
  factory MetadataPayload.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MetadataPayload(procesadoPorIa: false);
    }

    return MetadataPayload(
      // Forzamos cast seguro: si el valor existe pero no es String, devolvemos null
      textoProcesado: json['texto_procesado'] is String
          ? json['texto_procesado'] as String
          : null,
      urlAudioReferencia: json['url_audio_referencia'] is String
          ? json['url_audio_referencia'] as String
          : null,
      // procesado_por_ia puede llegar como bool o como int (0/1) en algunos
      // drivers; manejamos ambos casos de forma segura.
      procesadoPorIa: _parseBool(json['procesado_por_ia']),
      // duracion_segundos puede llegar como int o double (JSON num); usamos
      // conversión segura para evitar excepciones de cast.
      duracionSegundos: _parseInt(json['duracion_segundos']),
    );
  }

  // ── Helpers privados de cast seguro ─────────────────────────────────────
  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  String toString() => 'MetadataPayload('
      'textoProcesado: $textoProcesado, '
      'urlAudioReferencia: $urlAudioReferencia, '
      'procesadoPorIa: $procesadoPorIa, '
      'duracionSegundos: $duracionSegundos)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Enumeraciones de los campos nativos V2 (Buzón de Voz Asíncrono)
// ─────────────────────────────────────────────────────────────────────────────

/// Estado del ciclo de vida de un mensaje en el buzón de voz asíncrono.
enum EstadoReproduccion {
  pendiente,    // El dispositivo CoCo aún no fue notificado
  notificado,   // Se envió la señal al dispositivo pero no reprodujo aún
  reproducido,  // El adulto mayor escuchó el mensaje
  respondido,   // El adulto mayor emitió una respuesta
  desconocido,  // Valor de guarda ante futuros estados no mapeados
}

/// Prioridad del mensaje para la UI del familiar.
enum Prioridad {
  normal,
  urgente,
  desconocida, // Valor de guarda ante futuros valores no mapeados
}

// Helpers de parseo para los enums
EstadoReproduccion _parseEstadoReproduccion(String? value) {
  switch (value?.toUpperCase()) {
    case 'PENDIENTE':   return EstadoReproduccion.pendiente;
    case 'NOTIFICADO':  return EstadoReproduccion.notificado;
    case 'REPRODUCIDO': return EstadoReproduccion.reproducido;
    case 'RESPONDIDO':  return EstadoReproduccion.respondido;
    default:            return EstadoReproduccion.desconocido;
  }
}

Prioridad _parsePrioridad(String? value) {
  switch (value?.toUpperCase()) {
    case 'NORMAL':  return Prioridad.normal;
    case 'URGENTE': return Prioridad.urgente;
    default:        return Prioridad.desconocida;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelo principal: Interaccion (V2)
// ─────────────────────────────────────────────────────────────────────────────

/// Representa una fila completa de `historial_interacciones` (esquema V2).
class Interaccion {
  // ── Campos nativos de la tabla ──────────────────────────────────────────
  final String id;
  final String emisor;
  final String tipoEvento;

  // ── Campos nativos V2 (Buzón de Voz Asíncrono) ─────────────────────────
  /// Estado del mensaje dentro del ciclo de vida CoCo.
  final EstadoReproduccion estadoReproduccion;

  /// Prioridad del mensaje (NORMAL / URGENTE).
  final Prioridad prioridad;

  // ── Columna JSONB: metadata_payload ─────────────────────────────────────
  /// Payload enriquecido con transcripción, URL de audio y flag de IA.
  final MetadataPayload metadata;

  // ── Timestamp opcional para ordenar la lista en la UI ──────────────────
  final DateTime? creadoEn;

  const Interaccion({
    required this.id,
    required this.emisor,
    required this.tipoEvento,
    required this.estadoReproduccion,
    required this.prioridad,
    required this.metadata,
    this.creadoEn,
  });

  // ── Accesores de conveniencia (compatibilidad hacia atrás) ──────────────
  /// Alias directo a los campos del JSONB para no romper código existente.
  String? get textoProcesado     => metadata.textoProcesado;
  String? get urlAudioReferencia => metadata.urlAudioReferencia;
  bool    get procesadoPorIa     => metadata.procesadoPorIa;
  int?    get duracionSegundos   => metadata.duracionSegundos;

  // ── Helpers de estado para la UI ────────────────────────────────────────
  bool get esPendiente => estadoReproduccion == EstadoReproduccion.pendiente;
  bool get esUrgente   => prioridad == Prioridad.urgente;

  // ── Factory fromJson: contrato estricto con parseo seguro ───────────────
  factory Interaccion.fromJson(Map<String, dynamic> json) {
    // Extraemos el JSONB; si no es un Map lo tratamos como vacío
    final rawMetadata = json['metadata_payload'];
    final metadataMap = rawMetadata is Map<String, dynamic> ? rawMetadata : null;

    return Interaccion(
      // Campos nativos básicos
      id:         json['id']?.toString() ?? '',
      emisor:     json['emisor']?.toString() ?? '',
      tipoEvento: json['tipo_evento']?.toString() ?? '',

      // Campos nativos V2 — parseamos con enum para seguridad de tipos
      estadoReproduccion: _parseEstadoReproduccion(
        json['estado_reproduccion']?.toString(),
      ),
      prioridad: _parsePrioridad(
        json['prioridad']?.toString(),
      ),

      // JSONB: delegamos al sub-modelo MetadataPayload
      metadata: MetadataPayload.fromJson(metadataMap),

      // Timestamp opcional
      creadoEn: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Convierte el modelo a Map para logs o debugging. NO se usa para INSERT.
  Map<String, dynamic> toDebugMap() => {
    'id': id,
    'emisor': emisor,
    'tipo_evento': tipoEvento,
    'estado_reproduccion': estadoReproduccion.name.toUpperCase(),
    'prioridad': prioridad.name.toUpperCase(),
    'metadata': {
      'texto_procesado': metadata.textoProcesado,
      'url_audio_referencia': metadata.urlAudioReferencia,
      'procesado_por_ia': metadata.procesadoPorIa,
      'duracion_segundos': metadata.duracionSegundos,
    },
    'created_at': creadoEn?.toIso8601String(),
  };

  @override
  String toString() => 'Interaccion(id: $id, emisor: $emisor, '
      'tipo: $tipoEvento, estado: ${estadoReproduccion.name}, '
      'prioridad: ${prioridad.name})';
}
/// Configuración segura del cliente Supabase para el ecosistema COCO.
/// 
/// Principio de Arquitectura: "Ceguera de APIs".
/// Esta app actúa exclusivamente como Tablero de Control familiar y se comunica
/// única y estrictamente con Supabase (PostgREST, Auth, Storage, Realtime con RLS).
/// No existen ni deben existir llaves de AWS, OpenAI, Anthropic ni servicios externos aquí.
class SupabaseConfig {
  SupabaseConfig._();

  // Puede pasarse en tiempo de compilación con:
  // flutter run --dart-define=SUPABASE_URL=https://tu-id.supabase.co --dart-define=SUPABASE_ANON_KEY=tu-key
  // O reemplazar directamente las constantes aquí durante el desarrollo local:
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qhitfvbaydcknzdkugvf.supabase.co', // Valor por defecto actual del proyecto
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFoaXRmdmJheWRja256ZGt1Z3ZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0MTM0MTIsImV4cCI6MjEwMTk4OTQxMn0.ct93rhMYAkWj6Hhn5AD1rndq4ACRiDg1HdUBLQTG4XQ',
  );

  /// Valida que las credenciales obligatorias estén presentes
  static void validate() {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Faltan las credenciales de Supabase. '
        'Asegúrate de configurar SUPABASE_URL y SUPABASE_ANON_KEY en lib/config/supabase_config.dart '
        'o mediante --dart-define al ejecutar flutter run.',
      );
    }
  }
}

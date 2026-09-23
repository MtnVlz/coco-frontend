import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/main_layout.dart'; // Importamos tu nueva pantalla

/// Clave de navegador global.
/// Permite mostrar diálogos y rutas desde fuera del árbol de widgets,
/// fundamental para el Interceptor Global de Alertas SOS.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Asegura que los bindings de Flutter estén listos antes de inicializar Supabase
  WidgetsFlutterBinding.ensureInitialized();
  
  SupabaseConfig.validate();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const CocoAIApp());
}

class CocoAIApp extends StatelessWidget {
  const CocoAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoCo-AI',
      debugShowCheckedModeBanner: false,
      // ← Inyectamos la clave global del Navigator
      navigatorKey: navigatorKey,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF1B3B22), 
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark, 
        ),
        useMaterial3: true,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF132A18), 
          selectedItemColor: Color(0xFF4CAF50), 
          unselectedItemColor: Colors.white54,
        ),
      ),
      home: const main_layout(), // Flutter irá a buscarlo al archivo importado
    );
  }
}
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/main_layout.dart'; // Importamos tu nueva pantalla

Future<void> main() async {
  // Asegura que los bindings de Flutter estén listos antes de inicializar Supabase
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://qhitfvbaydcknzdkugvf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFoaXRmdmJheWRja256ZGt1Z3ZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0MTM0MTIsImV4cCI6MjEwMTk4OTQxMn0.ct93rhMYAkWj6Hhn5AD1rndq4ACRiDg1HdUBLQTG4XQ',
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
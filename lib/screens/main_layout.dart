import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show navigatorKey;
import '../models/interaccion_model.dart';
import '../widgets/sos_alert_dialog.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'family_screen.dart';
import 'settings_screen.dart';

class main_layout extends StatefulWidget {
  const main_layout({super.key});

  @override
  State<main_layout> createState() => _main_layoutState();
}

class _main_layoutState extends State<main_layout> {
  int _selectedIndex = 1;

  // ── Canal de Supabase Realtime para el interceptor SOS ──────────────────
  RealtimeChannel? _sosChannel;
  final _supabase = Supabase.instance.client;

  static const List<Widget> _widgetOptions = <Widget>[
    FamilyScreen(),
    HomeScreen(),
    ChatScreen(),
  ];

  // ── Conditions de disparo ────────────────────────────────────────────────
  // Reacciona ÚNICAMENTE si:
  //   • emisor == 'COCO'  Y
  //   • (tipo_evento == 'ALERTA_SOS'  O  prioridad == 'URGENTE')
  bool _esSosOUrgente(Map<String, dynamic> payload) {
    final emisor = payload['emisor']?.toString().toUpperCase();
    final tipoEvento = payload['tipo_evento']?.toString().toUpperCase();
    final prioridad = payload['prioridad']?.toString().toUpperCase();

    if (emisor != 'COCO') return false;
    return tipoEvento == 'ALERTA_SOS' || prioridad == 'URGENTE';
  }

  // ── Muestra el modal rojo usando el navigatorKey global ──────────────────
  void _mostrarAlertaSos(String mensajeEmergencia) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false, // No se cierra tocando fuera del modal
      barrierColor: Colors.transparent,
      builder: (_) => SosAlertDialog(mensajeEmergencia: mensajeEmergencia),
      useRootNavigator: true, // Se superpone a CUALQUIER ruta activa
    );
  }

  // ── Inicializa el listener Realtime ─────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _iniciarInterceptorSos();
  }

  void _iniciarInterceptorSos() {
    _sosChannel = _supabase
        .channel('sos-interceptor-global')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'historial_interacciones',
          callback: (payload) {
            final nuevaFila = payload.newRecord;
            if (!_esSosOUrgente(nuevaFila)) return;

            // Extraemos el texto de emergencia del JSONB metadata_payload
            final interaccion = Interaccion.fromJson(nuevaFila);
            final mensajeEmergencia =
                interaccion.textoProcesado ?? 'Emergencia detectada.';

            // Disparamos el modal rojo encima de todo
            _mostrarAlertaSos(mensajeEmergencia);
          },
        )
        .subscribe();
  }

  // ── Limpieza al salir ────────────────────────────────────────────────────
  @override
  void dispose() {
    _supabase.removeChannel(_sosChannel!);
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('CoCo AI', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          )
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Familia',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
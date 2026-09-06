import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B3B22),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Configuración', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white), // Flecha de retroceso blanca
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Dispositivo CoCo'),
          ListTile(
            leading: const Icon(Icons.volume_up, color: Colors.white),
            title: const Text('Volumen del altavoz', style: TextStyle(color: Colors.white)),
            subtitle: Slider(
              value: 0.7, // Aquí conectaremos nivel_volumen de la tabla dispositivos_coco
              onChanged: (val) {
                // TODO: Actualizar volumen en Supabase
              },
              activeColor: const Color(0xFF4CAF50),
              inactiveColor: Colors.white24,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.do_not_disturb_on, color: Colors.white),
            title: const Text('Modo No Molestar', style: TextStyle(color: Colors.white)),
            subtitle: const Text('22:00 hrs - 08:00 hrs', style: TextStyle(color: Colors.white54)),
            trailing: Switch(
              value: true, 
              onChanged: (val) {
                // TODO: Actualizar hora_inicio_silencio en Supabase
              }, 
              activeColor: const Color(0xFF4CAF50),
            ),
          ),
          
          const Divider(color: Colors.white24, height: 40),
          
          _buildSectionHeader('Gestión Familiar'),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text('Editar Perfil del Adulto Mayor', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () {
              print("Abrir edición de perfil");
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active, color: Colors.white),
            title: const Text('Alertas y Notificaciones', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () {},
          ),
          
          const Divider(color: Colors.white24, height: 40),
          
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              print("Cerrando sesión...");
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
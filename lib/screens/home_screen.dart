import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Función para mostrar el modal de nuevo recordatorio
  void _mostrarModalRecordatorio(BuildContext context) {
    final TextEditingController recordatorioController = TextEditingController();
    TimeOfDay horaSeleccionada = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder nos permite actualizar la interfaz solo dentro del modal (para mostrar la hora elegida)
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF132A18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('Nuevo Recordatorio', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: recordatorioController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Ej: Tómate la pastilla...',
                      hintStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4CAF50))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Botón para seleccionar la hora
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time, color: Color(0xFF4CAF50)),
                    title: Text(
                      'Hora: ${horaSeleccionada.format(context)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.white54, size: 20),
                    onTap: () async {
                      final TimeOfDay? nuevaHora = await showTimePicker(
                        context: context,
                        initialTime: horaSeleccionada,
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF4CAF50),
                                surface: Color(0xFF132A18),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (nuevaHora != null) {
                        setState(() {
                          horaSeleccionada = nuevaHora;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                  onPressed: () async {
                    final texto = recordatorioController.text.trim();
                    if (texto.isNotEmpty) {
                      // Construimos la fecha futura combinando hoy con la hora seleccionada
                      final ahora = DateTime.now();
                      final fechaAlarma = DateTime(
                        ahora.year, ahora.month, ahora.day, 
                        horaSeleccionada.hour, horaSeleccionada.minute
                      );

                      try {
                        await Supabase.instance.client.from('historial_interacciones').insert({
                          'emisor': 'APP',
                          'tipo_evento': 'RECORDATORIO', // Clasificación exacta del esquema
                          'estado_reproduccion': 'PENDIENTE',
                          'prioridad': 'NORMAL',
                          'timestamp': fechaAlarma.toIso8601String(), // Guardamos la hora exacta del evento
                          'metadata_payload': {
                            'texto_procesado': texto,
                            'procesado_por_ia': false,
                            'url_audio_referencia': null,
                          }
                        });
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        print("Error al guardar recordatorio: $e");
                      }
                    }
                  },
                  child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Para respetar el fondo del Dashboard
      // Botón flotante para agregar recordatorios
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarModalRecordatorio(context),
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.add_alarm, color: Colors.white),
        label: const Text('Recordatorio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.eco, size: 100, color: Color(0xFF4CAF50)),
          const SizedBox(height: 20),
          const Text(
            'Estado: Conectado y Funcionando',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Última interacción: Hace 3 horas',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 40),
          
          // Tarjeta de próximo recordatorio conectada a la BD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('historial_interacciones')
                  .stream(primaryKey: ['id'])
                  .eq('tipo_evento', 'RECORDATORIO') // Filtra solo recordatorios
                  .order('timestamp', ascending: false) // Trae el más reciente
                  .limit(1),
              builder: (context, snapshot) {
                String textoRecordatorio = 'Aún no hay recordatorios programados.';

                // Si hay datos, extraemos el texto del JSONB
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final data = snapshot.data!.first;
                  final payload = data['metadata_payload'] as Map<String, dynamic>?;
                  textoRecordatorio = payload?['texto_procesado'] ?? 'Recordatorio sin texto';
                }

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132A18),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.access_alarm, color: Color(0xFF4CAF50), size: 20),
                          SizedBox(width: 10),
                          Text('Próximo Recordatorio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(textoRecordatorio, style: const TextStyle(fontSize: 15, color: Colors.white70)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
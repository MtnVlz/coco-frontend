import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/interaccion_model.dart'; // Tu traductor de JSON

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  // Cliente de Supabase
  final _supabase = Supabase.instance.client;

  // ─────────────────────────────────────────────────────────────────────────
  // CAPA DE INTEGRACIÓN: Edge Function app_mensajeria
  // ─────────────────────────────────────────────────────────────────────────
  // Contrato JSON que acepta la Edge Function:
  //   {
  //     "mac_address" : string  → MAC del dispositivo CoCo de destino
  //     "tipo_mensaje": "TEXTO" | "AUDIO_NATIVO"
  //     "texto"       : string | null  → solo cuando tipo_mensaje == "TEXTO"
  //     "audio_url"   : string | null  → solo cuando tipo_mensaje == "AUDIO_NATIVO"
  //   }
  //
  // SEGURIDAD: El header Authorization: Bearer <jwt> se extrae de la sesión
  // activa de Supabase Auth y se inyecta manualmente para que la Edge Function
  // pueda validar la identidad del familiar antes de ejecutarse.
  // ─────────────────────────────────────────────────────────────────────────

  /// Método privado central que dispara el POST a la Edge Function.
  /// Acepta [tipoMensaje] ("TEXTO" o "AUDIO_NATIVO"), [texto] y [audioUrl].
  Future<void> _invocarEdgeFunction({
    required String tipoMensaje,
    String? texto,
    String? audioUrl,
  }) async {
    // 1. Extraer el JWT de la sesión activa de Supabase Auth.
    //    Si no hay sesión, no hay token y el servidor rechazaría la petición.
    final session = _supabase.auth.currentSession;
    final jwt = session?.accessToken;

    if (jwt == null) {
      print('Error: No hay sesión activa. El usuario debe iniciar sesión.');
      return;
    }

    // 2. Construir el body según el contrato acordado con el backend.
    final body = {
      'mac_address': '00:11:22:AA:BB:CC', // TODO: Obtener la MAC del dispositivo CoCo desde la BD
      'tipo_mensaje': tipoMensaje,
      'texto': texto,       // null cuando es AUDIO_NATIVO
      'audio_url': audioUrl, // null cuando es TEXTO
    };

    try {
      // 3. Disparar el POST. supabase.functions.invoke ya gestiona el baseUrl
      //    correcto del proyecto. Inyectamos el JWT explícitamente en headers
      //    para cumplir el requisito de seguridad de la Edge Function.
      final response = await _supabase.functions.invoke(
        'app_mensajeria',
        method: HttpMethod.post,
        headers: {
          'Authorization': 'Bearer $jwt', // ← JWT explícito requerido por la EF
          'Content-Type': 'application/json',
        },
        body: body,
      );

      // 4. Evaluar la respuesta
      if (response.status == 200 || response.status == 201) {
        print('app_mensajeria OK [${response.status}]: mensaje enrutado.');
      } else {
        final errorDetail = response.data != null
            ? jsonEncode(response.data)
            : 'Sin detalles del servidor';
        print('Error de app_mensajeria [${response.status}]: $errorDetail');
      }
    } on FunctionException catch (e) {
      print('FunctionException: ${e.reasonPhrase} — detalle: ${e.details}');
    } catch (e) {
      print('Error inesperado al contactar la Edge Function: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CASO 1: El familiar escribe un mensaje de TEXTO
  // tipo_mensaje = "TEXTO" | texto = <input del usuario> | audio_url = null
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _enviarMensaje() async {
    final texto = _messageController.text.trim();
    if (texto.isEmpty) return;

    // Limpiar el input inmediatamente para buena UX (no esperar la respuesta)
    _messageController.clear();

    await _invocarEdgeFunction(
      tipoMensaje: 'TEXTO',
      texto: texto,
      audioUrl: null,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CASO 2: El familiar graba un AUDIO desde la app
  // tipo_mensaje = "AUDIO_NATIVO" | texto = null | audio_url = <url en Storage>
  // (Se llama desde el botón de micrófono una vez que el audio esté subido
  //  al Supabase Storage y se tenga su URL pública o firmada)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _enviarAudio(String audioUrl) async {
    await _invocarEdgeFunction(
      tipoMensaje: 'AUDIO_NATIVO',
      texto: null,
      audioUrl: audioUrl,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          // StreamBuilder escucha la tabla en tiempo real
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase
                .from('historial_interacciones')
                .stream(primaryKey: ['id'])
                .order('timestamp', ascending: false), // Ordena del más nuevo al más viejo
            builder: (context, snapshot) {
              // 1. Estado de carga
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
              }
              
              // 2. Manejo de errores
              if (snapshot.hasError) {
                // Imprime el error en la consola de Visual Studio
                print("Error de Supabase: ${snapshot.error}");
                // Muestra el error real en la pantalla del celular en color rojo
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "Error detallado:\n${snapshot.error}", 
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  )
                );
              }

              // 3. Obtener los datos y traducirlos con el Modelo
              final datos = snapshot.data ?? [];
              final mensajes = datos.map((json) => Interaccion.fromJson(json)).toList();

              // 4. Si no hay mensajes aún
              if (mensajes.isEmpty) {
                return const Center(
                  child: Text(
                    "Aún no hay mensajes.\nEscribe uno para comenzar.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              // 5. Construir la lista visual
              return ListView.builder(
                reverse: true, // Los más recientes abajo
                padding: const EdgeInsets.all(15),
                itemCount: mensajes.length,
                itemBuilder: (context, index) {
                  final interaccion = mensajes[index];
                  
                  // Definimos si el mensaje es nuestro (APP) o del abuelo (COCO)
                  final isMe = interaccion.emisor == 'APP';
                  // Verificamos si es un audio
                  final isAudio = interaccion.tipoEvento == 'AUDIO_DIRECTO' || interaccion.urlAudioReferencia != null;

                  return _buildMessageBubble(
                    text: interaccion.textoProcesado ?? '', 
                    isMe: isMe,
                    isAudio: isAudio,
                    duration: interaccion.duracionSegundos != null 
                        ? "0:0${interaccion.duracionSegundos}" // Formato rápido de prueba
                        : "0:00",
                  );
                },
              );
            },
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  // --- El resto de tus métodos de diseño (Globo, Barra de escritura, etc.) se mantienen IGUAL ---
  
  Widget _buildMessageBubble({required String text, required bool isMe, required bool isAudio, String? duration}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 15, left: isMe ? 50 : 0, right: isMe ? 0 : 50),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF4CAF50) : const Color(0xFF132A18),
          borderRadius: BorderRadius.circular(15).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(15),
            bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(15),
          ),
          border: !isMe ? Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)) : null,
        ),
        child: isAudio 
            ? _buildAudioPlayer(duration ?? "0:00") 
            : _buildTextContent(text, isMe),        
      ),
    );
  }

  Widget _buildTextContent(String text, bool isMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe) ...[
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic, size: 14, color: Colors.white54),
              SizedBox(width: 5),
              Text("Transcrito por IA", style: TextStyle(fontSize: 10, color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 5),
        ],
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ],
    );
  }

  Widget _buildAudioPlayer(String duration) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 40, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(duration, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF132A18),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribe para que Coco lo lea...',
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.transparent,
            child: IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF4CAF50), size: 24),
              onPressed: () {
                _enviarMensaje();
              },
            ),
          ),
          CircleAvatar(
            backgroundColor: const Color(0xFF4CAF50),
            child: IconButton(
              icon: const Icon(Icons.mic, color: Colors.white, size: 22),
              onPressed: () {
                // TODO: Implementar grabación de audio con flutter_sound o record,
                // subirlo a Supabase Storage y obtener su URL. Luego llamar:
                // _enviarAudio(audioUrl);
                //
                // Ejemplo de llamada final una vez obtenida la URL:
                // final audioUrl = await _subirAudioAStorage(archivoGrabado);
                // _enviarAudio(audioUrl);
                print('Grabación de audio pendiente de implementar.');
              },
            ),
          ),
        ],
      ),
    );
  }
}
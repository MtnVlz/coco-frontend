import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

/// Modal de emergencia SOS.
/// Se muestra sobre cualquier pantalla de la app cuando CoCo dispara una
/// alerta con tipo_evento == 'ALERTA_SOS' o prioridad == 'URGENTE'.
///
/// Diseño: pantalla completa roja brillante, imposible de ignorar.
/// Cierre: solo mediante el botón "Entendido / Descartar Alerta".
class SosAlertDialog extends StatefulWidget {
  /// Texto de la emergencia, extraído de metadata_payload → texto_procesado.
  final String mensajeEmergencia;

  const SosAlertDialog({
    super.key,
    required this.mensajeEmergencia,
  });

  @override
  State<SosAlertDialog> createState() => _SosAlertDialogState();
}

class _SosAlertDialogState extends State<SosAlertDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // ── Animación de pulso para el ícono central ─────────────────────────
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ── Vibracion de emergencia ───────────────────────────────────────────
    _dispararVibracion();
  }

  Future<void> _dispararVibracion() async {
    final tieneVibrador = await Vibration.hasVibrator();
    if (!tieneVibrador) return;

    // Patron: vibra fuerte, pausa, vibra fuerte, pausa, vibra fuerte
    // [espera, duracion, espera, duracion, espera, duracion] en ms
    final tieneAmplitud = await Vibration.hasAmplitudeControl();
    if (tieneAmplitud) {
      Vibration.vibrate(
        pattern: [0, 600, 200, 600, 200, 1000],
        intensities: [0, 255, 0, 255, 0, 255],
      );
    } else {
      Vibration.vibrate(pattern: [0, 600, 200, 600, 200, 1000]);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    Vibration.cancel(); // Cancela cualquier vibración en curso al cerrar
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Evita que el botón "atrás" del sistema cierre el modal accidentalmente
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          // ── Fondo rojo brillante a pantalla completa ─────────────────
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFB71C1C), // Rojo oscuro intenso
                Color(0xFFD32F2F), // Rojo medio
                Color(0xFFF44336), // Rojo brillante
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // ── Ícono pulsante ─────────────────────────────────
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.shade900.withOpacity(0.6),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        size: 72,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Título de alerta ───────────────────────────────
                  const Text(
                    '¡ALERTA SOS!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          offset: Offset(0, 3),
                          blurRadius: 8,
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Subtítulo ──────────────────────────────────────
                  Text(
                    'CoCo detectó una emergencia',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Caja con el mensaje de la emergencia ───────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'MENSAJE DE COCO:',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.mensajeEmergencia.isNotEmpty
                              ? widget.mensajeEmergencia
                              : 'Se detectó una situación de emergencia. Por favor, verifica el estado de tu familiar.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Botón de descartar ─────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check_circle_outline, size: 26),
                      label: const Text(
                        'Entendido / Descartar Alerta',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFD32F2F),
                        elevation: 6,
                        shadowColor: Colors.black38,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Aviso de registro ──────────────────────────────
                  Text(
                    'Esta alerta quedará registrada en el historial.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

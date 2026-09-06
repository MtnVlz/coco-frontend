import 'package:flutter/material.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  // Datos simulados basados en la tabla 'red_apoyo' y 'usuarios_app'
  final List<Map<String, dynamic>> _contacts = const [
    {
      "nombre": "Martín (Tú)",
      "rol": "Administrador",
      "apodo": "Nieto / Mi niño",
      "online": true,
    },
    {
      "nombre": "Ana",
      "rol": "Contacto",
      "apodo": "Hija",
      "online": false,
      "last_seen": "Hace 2 horas"
    },
    {
      "nombre": "Dr. Ramírez",
      "rol": "Contacto",
      "apodo": "Doctor",
      "online": false,
      "last_seen": "Ayer"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cabecera con botón para añadir familiares
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Contactos',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  print("Abrir modal para agregar contacto");
                },
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Añadir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Lista de contactos
        Expanded(
          child: ListView.builder(
            itemCount: _contacts.length,
            itemBuilder: (context, index) {
              final contact = _contacts[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF132A18),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
                    radius: 25,
                    // Aquí irá el avatar_url en el futuro
                    child: Text(
                      contact["nombre"].substring(0, 1),
                      style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        contact["nombre"],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        contact["rol"],
                        style: TextStyle(
                          color: contact["rol"] == 'Administrador' ? const Color(0xFF4CAF50) : Colors.white54, 
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        'Reconoce como: "${contact["apodo"]}"',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.circle, 
                            size: 10, 
                            color: contact["online"] ? Colors.greenAccent : Colors.white38
                          ),
                          const SizedBox(width: 5),
                          Text(
                            contact["online"] ? 'En línea' : 'Última vez: ${contact["last_seen"]}',
                            style: TextStyle(
                              color: contact["online"] ? Colors.greenAccent : Colors.white54, 
                              fontSize: 12
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                    onPressed: () {
                      print("Editar apodos o permisos");
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
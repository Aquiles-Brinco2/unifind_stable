import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:objetos_perdidos/services/main_class.dart'; // Asegúrate de tener el modelo correcto

class PostDetailScreen extends StatelessWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    // Decodificar la imagen de base64
    Uint8List decodedImage = base64Decode(post.lostItem.image ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Objeto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const Text(
              'Detalles de la Publicación',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Nombre: ${post.lostItem.name}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Descripción: ${post.lostItem.description}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Categoría: ${post.lostItem.category}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Ubicación: ${post.lostItem.location}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Carrera: ${post.lostItem.career}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Estado: ${post.lostItem.found ? 'Encontrado' : 'Perdido'}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            // Mostrar la imagen en base64 si existe
            if (post.lostItem.image.isNotEmpty)
              Image.memory(
                decodedImage,
                width: 200, // Puedes ajustar el tamaño
                height: 200,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:objetos_perdidos/pages/comment_sceen.dart';
import 'package:objetos_perdidos/pages/my_post_screen.dart';
import 'package:objetos_perdidos/pages/porfile_screen.dart';
import 'package:objetos_perdidos/pages/post_create_screen.dart';
import 'package:objetos_perdidos/services/comments_delete.dart';
import 'package:objetos_perdidos/services/comments_get.dart';
import 'package:objetos_perdidos/services/main_class.dart';
import 'package:intl/intl.dart';
import 'package:objetos_perdidos/services/posts_get_Encontrados.dart';
import 'package:objetos_perdidos/services/posts_get_Perdidos.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para formatear la fecha

void main() {
  runApp(const LostAndFoundApp());
}

class LostAndFoundApp extends StatelessWidget {
  const LostAndFoundApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Post>> futurePosts;
  int _selectedIndex = 0;
  bool isLost =
      true; // Variable para saber si estamos viendo "Perdido" o "Encontrado"
  String postStatus = "completado"; // Estado por defecto
  List<Post> _allPosts =
      []; // Lista para almacenar todas las publicaciones sin filtrar
  List<Post> _filteredPosts = []; // Lista filtrada por la búsqueda
  final TextEditingController _searchController =
      TextEditingController(); // Controlador de búsqueda

  @override
  void initState() {
    super.initState();
    futurePosts = fetchLostPosts(); // Por defecto, cargamos los posts perdidos
  }

  // Función para refrescar los posts dependiendo del estado (perdido o encontrado)
  Future<void> _refreshPosts() async {
    setState(() {
      futurePosts = isLost
          ? fetchLostPosts(postStatus: postStatus)
          : fetchFoundPosts(postStatus: postStatus);
    });
  }

  // Función que maneja la búsqueda cuando se presiona el botón de búsqueda
  Future<void> _searchPosts() async {
    String searchQuery = _searchController.text.trim();
    setState(() {
      // Cuando el usuario presiona el botón de búsqueda, realizamos una nueva consulta
      futurePosts = isLost
          ? fetchLostPosts(postStatus: postStatus, name: searchQuery)
          : fetchFoundPosts(postStatus: postStatus, name: searchQuery);
    });
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Evitar recargar la pantalla actual

    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreatePublicationScreen(),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MyPostsScreen(userId: ''),
        ),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
      );
    }
  }

  // Función para manejar los botones de "Perdido" y "Encontrado"
  void _toggleLostFound(bool isLostStatus) {
    setState(() {
      isLost = isLostStatus;
      futurePosts = isLost ? fetchLostPosts() : fetchFoundPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Objetos Perdidos'),
        actions: [
          // Barra de búsqueda en el AppBar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Barra de texto para buscar por nombre
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre...',
                      //prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                // Botón de búsqueda
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed:
                      _searchPosts, // Ejecuta la búsqueda al presionar el botón
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Botones para filtrar entre "Perdido" y "Encontrado"
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _toggleLostFound(true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15.0, horizontal: 30.0),
                    minimumSize: const Size(150, 50),
                  ), // Mostrar los perdidos
                  child: const Text(
                    'Perdido',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _toggleLostFound(false),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15.0, horizontal: 30.0),
                    minimumSize: const Size(150, 50),
                  ), // Mostrar los encontrados
                  child: const Text(
                    'Encontrado',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: postStatus,
            items: const [
              DropdownMenuItem(value: "pendiente", child: Text("Pendiente")),
              DropdownMenuItem(value: "completado", child: Text("Completado")),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  postStatus = newValue;
                  _refreshPosts();
                });
              }
            },
          ),

          // Aquí es donde se muestran los posts
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPosts,
              child: FutureBuilder<List<Post>>(
                future: futurePosts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('No hay publicaciones disponibles.'));
                  }

                  final posts = snapshot.data!;
                  _allPosts =
                      posts; // Guardamos todas las publicaciones para filtrarlas
                  _filteredPosts =
                      posts; // Inicialmente, mostramos todas las publicaciones

                  return ListView.builder(
                    itemCount: _filteredPosts.length,
                    itemBuilder: (context, index) {
                      final post = _filteredPosts[index];
                      return PostCard(post: post);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.red,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Crear',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Mis Publicaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        selectedIconTheme: const IconThemeData(color: Colors.red),
        unselectedIconTheme: const IconThemeData(color: Colors.white),
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Future<List<Comment>> futureComments;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    futureComments =
        fetchCommentsByPostId(widget.post.id); // Obtener los comentarios
    _loadCurrentUserId(); // Cargar el ID del usuario actual
  }

  // Cargar el ID del usuario desde SharedPreferences
  _loadCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId =
          prefs.getString('user_id'); // Obtener el ID del usuario actual
    });
  }

  // Función para borrar el comentario
  Future<void> _deleteComment(String commentId) async {
    try {
      await deleteComment(commentId); // Llamar al servicio de eliminación
      setState(() {
        futureComments =
            fetchCommentsByPostId(widget.post.id); // Refrescar los comentarios
      });
    } catch (e) {
      print('Error al eliminar el comentario: $e');
    }
  }

  // Mostrar un cuadro de confirmación para borrar el comentario
  _showDeleteConfirmationDialog(String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content:
              const Text('¿Está seguro de que quiere borrar este comentario?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _deleteComment(commentId); // Llamar a la función de eliminación
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Borrar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImage() {
    try {
      if (widget.post.lostItem.image.isNotEmpty) {
        try {
          Uint8List imageBytes = base64Decode(widget.post.lostItem.image);
          if (imageBytes.isNotEmpty) {
            return Image.memory(
              imageBytes,
              height: 250,
              width: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/skibidihomero.png',
                  height: 250,
                  width: 300,
                  fit: BoxFit.cover,
                );
              },
            );
          }
        } catch (e) {
          print('Error decodificando imagen: $e');
        }
      }
      return Image.asset(
        'assets/images/skibidihomero.png',
        height: 250,
        width: 300,
        fit: BoxFit.cover,
      );
    } catch (e) {
      print('Error inesperado con la imagen: $e');
      return Image.asset(
        'assets/images/skibidihomero.png',
        height: 250,
        width: 300,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildImage(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.post.lostItem.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Descripción: ${widget.post.lostItem.description}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ubicación: ${widget.post.lostItem.location}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Carrera: ${widget.post.lostItem.career}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Botón para comentarios
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CreateCommentScreen(postId: widget.post.id),
                        ),
                      );
                    },
                    child: const Text('Comentar'),
                  ),

                  // Cargar y mostrar los comentarios
                  const SizedBox(height: 10),
                  FutureBuilder<List<Comment>>(
                    future: futureComments,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No hay comentarios aún.');
                      }

                      final comments = snapshot.data!;
                      return Column(
                        children: comments
                            .map((comment) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 15,
                                        backgroundColor: Colors.blue,
                                        child: Text(
                                          comment.userName.isNotEmpty
                                              ? comment.userName[
                                                  0] // Inicial del autor
                                              : 'U', // Valor por defecto
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Usuario: ${comment.userName}', // Nombre de usuario
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(comment.content),
                                            const SizedBox(height: 5),
                                            Text(
                                              'Publicado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(comment.createdAt))}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Mostrar el botón de borrar solo si el usuario es el mismo
                                      if (currentUserId == comment.userId)
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () {
                                            _showDeleteConfirmationDialog(comment
                                                .id); // Mostrar diálogo de confirmación
                                          },
                                        ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

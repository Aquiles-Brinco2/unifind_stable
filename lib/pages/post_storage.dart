import 'package:flutter/material.dart';
import 'package:objetos_perdidos/pages/post_detail_screen.dart';
import 'package:objetos_perdidos/services/main_class.dart';
import 'package:objetos_perdidos/services/posts_get_storage.dart'; // Servicio que trae los posts

class StoredPostsScreen extends StatefulWidget {
  const StoredPostsScreen({super.key});

  @override
  _StoredPostsScreenState createState() => _StoredPostsScreenState();
}

class _StoredPostsScreenState extends State<StoredPostsScreen> {
  late Future<List<Post>> futurePosts;

  @override
  void initState() {
    super.initState();
    // Traer todos los posts con found == true
    futurePosts = fetchFoundPosts();
  }

  Future<void> _refreshPosts() async {
    setState(() {
      futurePosts = fetchFoundPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Almacenados'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: FutureBuilder<List<Post>>(
          future: futurePosts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay objetos almacenados'));
            }

            final posts = snapshot.data!;
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(post: post);
              },
            );
          },
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.lostItem.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text('Descripción: ${post.lostItem.description}'),
            const SizedBox(height: 5),
            Text('Estado: ${post.lostItem.found ? 'Encontrado' : 'Perdido'}'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(post: post),
                  ),
                );
              },
              child: const Text('Ver Detalles'),
            ),
          ],
        ),
      ),
    );
  }
}

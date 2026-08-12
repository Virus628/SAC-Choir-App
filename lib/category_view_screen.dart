import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'song_model.dart';
import 'lyrics_screen.dart';

class CategoryViewScreen extends StatelessWidget {
  final String categoryTitle;
  final bool isAdmin;
  
  const CategoryViewScreen({
    super.key, 
    required this.categoryTitle, 
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryTitle)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('songs')
            .where('category', isEqualTo: categoryTitle)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading songs.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No $categoryTitle songs found yet.', style: const TextStyle(color: Colors.grey)));
          }

          List<Song> songs = snapshot.data!.docs.map((doc) => Song.fromFirestore(doc)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text('By ${song.composer}', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                  trailing: const Icon(Icons.lyrics),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LyricsScreen(
                          song: song, 
                          isAdmin: isAdmin, // *** PASS COMPONENT STATE HERE ***
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

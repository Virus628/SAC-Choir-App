import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String id;
  final String title;
  final String category;
  final String lyrics;
  final String composer; // *** NEW FIELD ***

  Song({
    required this.id,
    required this.title,
    required this.category,
    required this.lyrics,
    required this.composer,
  });

  factory Song.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Song(
      id: doc.id,
      title: data['title'] ?? 'Untitled',
      category: data['category'] ?? 'General',
      lyrics: data['lyrics'] ?? '',
      composer: data['composer'] ?? 'Unknown Composer', // *** NEW FIELD FALLBACK ***
    );
  }
}

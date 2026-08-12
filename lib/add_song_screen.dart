import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'song_model.dart';
import 'lyrics_screen.dart';

class AddSongScreen extends StatefulWidget {
  const AddSongScreen({super.key});

  @override
  State<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends State<AddSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _composerController = TextEditingController();
  final _lyricsController = TextEditingController();
  
  // The exact categories from your UI design
  final List<String> _categories = [
    'Entrance Hymn', 'Kyrie', 'Gloria', 'Gospel Acclamation',
    'Offertory', 'Sanctus', 'Memorial Acclamation', 'Great Amen',
    'The Lord\'s Prayer', 'Agnus Dei', 'Communion', 'Recessional Hymn'
  ];
  
  String? _selectedCategory;
  bool _isUploading = false;

  void _submitData() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields and select a category.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Pushing data to Firestore (fully supports offline-first local caching)
      await FirebaseFirestore.instance.collection('songs').add({
        'title': _titleController.text.trim(),
        'composer': _composerController.text.trim(),
        'category': _selectedCategory,
        'lyrics': _lyricsController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song added successfully! 🎉')),
        );
        // Clear inputs after successful local write
        _titleController.clear();
        _composerController.clear();
        _lyricsController.clear();
        setState(() {
          _selectedCategory = null;
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving song: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _composerController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
      ),
      body: _isUploading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Half: Form Input Panel
                Expanded(
                  flex: 7,
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Title Input
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Song Title',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            ),
                            validator: (value) => value!.isEmpty ? 'Enter a title' : null,
                          ),
                          const SizedBox(height: 12),

                          // Composer Input
                          TextFormField(
                            controller: _composerController,
                            decoration: InputDecoration(
                              labelText: 'Composer / Arrangement Owner',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            ),
                            validator: (value) => value!.isEmpty ? 'Enter composer (e.g., Bob Hurd, Traditional)' : null,
                          ),
                          const SizedBox(height: 12),

                          // Category Picker Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            hint: const Text('Select Mass Part / Category'),
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            ),
                            items: _categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedCategory = value),
                          ),
                          const SizedBox(height: 12),

                          // Lyrics Area Box
                          TextFormField(
                            controller: _lyricsController,
                            maxLines: 6,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              labelText: 'Paste Lyrics Here...',
                              alignLabelWithHint: true,
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            ),
                            validator: (value) => value!.isEmpty ? 'Enter the lyrics' : null,
                          ),
                          const SizedBox(height: 16),

                          // Save Actions Button
                          // Wrap the button with a full-width SizedBox inside lib/add_song_screen.dart
                          SizedBox(
                            width: double.infinity, // *** MAKES IT STRETCH EDGE-TO-EDGE ***
                            child: ElevatedButton(
                              onPressed: _submitData,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16), // Slightly taller padding for better touch area
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text(
                                'Save & Sync Song', 
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const Divider(thickness: 2, height: 32),
                
                // Bottom Half: Live Verification Feed
                Text(
                  'All Saved Songs (Sorted by Newest Added First)', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 8),
                
                Expanded(
                  flex: 4,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('songs').orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('0 songs found in database cache.', style: TextStyle(color: Colors.grey)));
                      }
                      
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, idx) {
                          var doc = snapshot.data!.docs[idx];
                          
                          // Convert to our safe Song object FIRST before pulling fields!
                          Song safeSong = Song.fromFirestore(doc);
                          
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              dense: true,
                              title: Text(safeSong.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('By ${safeSong.composer} • ${safeSong.category}'),
                              leading: const Icon(Icons.cloud_done, color: Colors.green),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LyricsScreen(song: safeSong, isAdmin: true),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'song_model.dart';

class LyricsScreen extends StatefulWidget {
  final Song song;
  final bool isAdmin;
  const LyricsScreen({super.key, required this.song, this.isAdmin = false});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  double _fontSize = 19.0;
  bool _isEditing = false;

  // Controllers for editing
  late TextEditingController _titleController;
  late TextEditingController _composerController;
  late TextEditingController _lyricsController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _composerController = TextEditingController(text: widget.song.composer);
    _lyricsController = TextEditingController(text: widget.song.lyrics);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _composerController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  // Action to update song in Firestore
  void _updateSong() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await FirebaseFirestore.instance
          .collection('songs')
          .doc(widget.song.id)
          .update({
            'title': _titleController.text.trim(),
            'composer': _composerController.text.trim(),
            'lyrics': _lyricsController.text.trim(),
          });

      if (!mounted) return;
      setState(() => _isEditing = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Song updated successfully!')),
      );
      // Pop back to category view since the local object data changed
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  // Action to delete song from Firestore
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Song?'),
          content: Text(
            'Are you sure you want to permanently remove "${widget.song.title}"? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                final messenger = ScaffoldMessenger.of(dialogContext);
                final navigator = Navigator.of(dialogContext);
                try {
                  await FirebaseFirestore.instance
                      .collection('songs')
                      .doc(widget.song.id)
                      .delete();

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Song deleted successfully. 🗑️'),
                    ),
                  );
                  navigator.pop(); // Close lyrics screen
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _isEditing
                ? const Text('Edit Song Details')
                : Text(widget.song.title),
        actions: [
          // 1. If we are currently in editing mode, show the save checkmark
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: _updateSong,
            )
          // 2. If we are NOT editing, ONLY show management tools if they are the verified Admin!
          else if (widget.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_note),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Song',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _confirmDelete,
              tooltip: 'Delete Song',
            ),
          ],
        ],
      ),
      body: SafeArea(
        child:
            _isEditing
                ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Song Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _composerController,
                          decoration: const InputDecoration(
                            labelText: 'Composer / Arrangement Owner',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lyricsController,
                          maxLines: 12,
                          decoration: const InputDecoration(
                            labelText: 'Song Lyrics',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : Column(
                  children: [
                    // Text resizing controls
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed:
                                () => setState(
                                  () =>
                                      _fontSize =
                                          _fontSize > 14
                                              ? _fontSize - 2
                                              : _fontSize,
                                ),
                          ),
                          const Text(
                            "Adjust Text Size",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed:
                                () => setState(
                                  () =>
                                      _fontSize =
                                          _fontSize < 36
                                              ? _fontSize + 2
                                              : _fontSize,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              Text(
                                'By ${widget.song.composer}',
                                style: TextStyle(
                                  fontSize: _fontSize - 4,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.song.lyrics,
                                style: TextStyle(
                                  fontSize: _fontSize,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

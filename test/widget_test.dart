import 'package:flutter_test/flutter_test.dart';

import 'package:church_app/song_model.dart';

void main() {
  group('Song.fromMap', () {
    test('maps all fields with defaults when data is full', () {
      final song = Song.fromMap('song-1', {
        'title': 'Amazing Grace',
        'category': 'Entrance Hymn',
        'composer': 'John Newton',
        'lyrics': 'Amazing grace...',
      });

      expect(song.id, 'song-1');
      expect(song.title, 'Amazing Grace');
      expect(song.category, 'Entrance Hymn');
      expect(song.composer, 'John Newton');
      expect(song.lyrics, 'Amazing grace...');
    });

    test('uses safe fallbacks when fields are missing', () {
      final song = Song.fromMap('song-2', {});

      expect(song.title, 'Untitled');
      expect(song.category, 'General');
      expect(song.composer, 'Unknown Composer');
      expect(song.lyrics, '');
    });
  });
}
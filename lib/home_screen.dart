import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_view_screen.dart';
import 'add_song_screen.dart';
import 'lyrics_screen.dart';
import 'song_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SACAppHomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const SACAppHomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<SACAppHomeScreen> createState() => _SACAppHomeScreenState();
}

class _SACAppHomeScreenState extends State<SACAppHomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = "";
  
  bool _isAdminMode = false;

  final List<String> songCategories = [
    'Entrance Hymn', 'Kyrie', 'Gloria', 'Gospel Acclamation',
    'Offertory', 'Sanctus', 'Memorial Acclamation', 'Great Amen',
    'The Lord\'s Prayer', 'Agnus Dei', 'Communion', 'Recessional Hymn',
  ];

  // Opens the browser to download the updated APK
  Future<void> _downloadLatestUpdate() async {
    final Uri url = Uri.parse('https://drive.google.com/drive/folders/1AwmsFcNHxD3TjScqpx_839PJEiPQgOqN?usp=drive_link'); 
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch the download link');
    }
  }

  // Pushes both height and the vertical alignment offset up to Firebase
  void _updateRemoteLayoutSettings(double height, double alignmentY) {
    FirebaseFirestore.instance.collection('app_settings').doc('homepage').set({
      'imageHeight': height,
      'imageAlignmentY': alignmentY,
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isSearching = _searchQuery.isNotEmpty;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('app_settings').doc('homepage').snapshots(),
      builder: (context, settingsSnapshot) {
        // Safe default parameters
        double activeHeight = 130.0;
        double activeAlignmentY = 0.0;

        if (settingsSnapshot.hasData && settingsSnapshot.data!.exists) {
          var data = settingsSnapshot.data!.data() as Map<String, dynamic>;
          activeHeight = (data['imageHeight'] ?? 130.0).toDouble();
          activeAlignmentY = (data['imageAlignmentY'] ?? 0.0).toDouble();
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: widget.isDarkMode ? const Color(0xFF1F1F1F) : Colors.indigo,
            foregroundColor: Colors.white,
            elevation: 2,
            
            // 1. We remove the default auto-leading hamburger menu
            automaticallyImplyLeading: false, 
            
            title: GestureDetector(
              onLongPress: () {
                setState(() {
                  _isAdminMode = !_isAdminMode; 
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isAdminMode 
                        ? 'Admin Crop Tool Active!' 
                        : 'Updated Successfully!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                _isAdminMode ? 'Image Framing' : 'SAC Choir App', 
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 20,
                ),
              ),
            ),
            centerTitle: true,
            
            // 2. We arrange actions: Night Mode first, then the Hamburger Icon manually!
            actions: [
              IconButton(
                icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: widget.onThemeToggle,
                tooltip: 'Toggle Theme Mode',
              ),
              // Builder widget is needed here to get the correct context to open the drawer
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                  tooltip: 'Open Menu',
                ),
              ),
            ],
          ),
          
          // 🍔 Updated Hamburger Drawer Panel
          endDrawer: Drawer(
            child: Column(
              children: [
                // Clean space at the top (no header card/banner)
                SizedBox(height: MediaQuery.of(context).padding.top + 16),
                
                // Option 1: Update Application Button
                ListTile(
                  leading: const Icon(Icons.system_update, color: Colors.blue),
                  title: const Text('Update/Download App'),
                  subtitle: const Text('Check for new app features'),
                  onTap: () {
                    Navigator.pop(context); // Close the side drawer
                    _downloadLatestUpdate(); // Trigger download action
                  },
                ),

                // Option 2: Database Console (Displays ONLY if Admin Mode is turned on)
                if (_isAdminMode) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: Colors.orange),
                    title: const Text('Database Console'),
                    subtitle: const Text('Add and manage church songs'),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddSongScreen()),
                      );
                    },
                  ),
                ],
                
                // Pushes the version text down to the very bottom like a footer
                const Spacer(),
                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Version 1.2.0',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white38 : Colors.black38,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      
                      // Live Adjusted Crop Header Box
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/bg.jpeg', 
                            height: activeHeight, 
                            width: double.infinity,
                            fit: BoxFit.cover,
                            alignment: Alignment(0.0, activeAlignmentY),
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: activeHeight,
                              color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                              child: const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),

                      // Admin Realtime Panning Sliders
                      if (_isAdminMode) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode ? Colors.grey[900] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blueAccent.withAlpha(128)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const SizedBox(width: 80, child: Text("Frame Height:", style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(
                                    child: Slider(
                                      value: activeHeight.clamp(80.0, 300.0),
                                      min: 80.0,
                                      max: 300.0,
                                      divisions: 22,
                                      onChanged: (double val) => _updateRemoteLayoutSettings(val, activeAlignmentY),
                                    ),
                                  ),
                                  Text("${activeHeight.round()}px"),
                                ],
                              ),
                              Row(
                                children: [
                                  const SizedBox(width: 80, child: Text("Vertical Pan:", style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(
                                    child: Slider(
                                      value: activeAlignmentY.clamp(-1.0, 1.0),
                                      min: -1.0,
                                      max: 1.0,
                                      divisions: 40,
                                      onChanged: (double val) => _updateRemoteLayoutSettings(activeHeight, val),
                                    ),
                                  ),
                                  Text(activeAlignmentY == 0.0 
                                      ? "Center" 
                                      : activeAlignmentY < 0 
                                          ? "Top" 
                                          : "Bottom"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Search Input Field
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.trim();
                          });
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: isSearching 
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = "");
                                  },
                                )
                              : null,
                          hintText: 'Search for Song Titles...',
                          hintStyle: GoogleFonts.poppins(fontSize: 14),
                          filled: true,
                          fillColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                Expanded(
                  child: isSearching
                      ? _buildSearchResultsView(_isAdminMode)
                      : _buildStandardCategoriesView(_isAdminMode),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStandardCategoriesView(bool adminFlag) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: songCategories.length,
            itemBuilder: (context, index) {
              final String categoryName = songCategories[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                child: ListTile(
                  title: Text(categoryName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, 
                      fontSize: 15,
                      letterSpacing: 0.3,)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryViewScreen(categoryTitle: categoryName, isAdmin: adminFlag),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSearchResultsView(bool adminFlag) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('songs').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No songs found in database.'));
        }

        List<Song> allSongs = snapshot.data!.docs.map((doc) => Song.fromFirestore(doc)).toList();
        List<Song> filteredSongs = allSongs.where((song) {
          return song.title.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredSongs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('No songs matches found for "$_searchQuery"', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: filteredSongs.length,
          itemBuilder: (context, index) {
            final song = filteredSongs[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              child: ListTile(
                title: Text(song.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text('By ${song.composer} • ${song.category}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),),
                trailing: const Icon(Icons.lyrics),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LyricsScreen(song: song, isAdmin: adminFlag),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'category_view_screen.dart';
import 'add_song_screen.dart';
import 'lyrics_screen.dart';
import 'song_model.dart';
import 'song_categories.dart';
import 'app_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_auth.dart';

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

  String _appVersion = '';

  // Local preview while the image-framing sliders are being dragged; commits
  // to Firestore once per gesture via onChangeEnd to avoid write spam.
  double? _dragHeight;
  double? _dragAlignmentY;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = '${info.version}+${info.buildNumber}');
      }
    } catch (_) {
      // Leave _appVersion empty; the drawer falls back to 'Version -'.
    }
  }

  // Opens the browser to download the updated build
  Future<void> _downloadLatestUpdate() async {
    final Uri url = Uri.parse(AppConfig.updateDownloadUrl);

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

        // Local overrides take priority while a slider is being dragged.
        final previewHeight = _dragHeight ?? activeHeight;
        final previewAlignmentY = _dragAlignmentY ?? activeAlignmentY;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: widget.isDarkMode ? const Color(0xFF1F1F1F) : Colors.indigo,
            foregroundColor: Colors.white,
            elevation: 2,
            
            // 1. We remove the default auto-leading hamburger menu
            automaticallyImplyLeading: false, 
            
            title: GestureDetector(
              onLongPress: () async {
                if (_isAdminMode) {
                  setState(() {
                    _isAdminMode = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Admin Mode Disabled'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                final adminUser = await ensureAdminSignedIn(context);
                if (adminUser == null || !mounted) return;

                setState(() {
                  _isAdminMode = true;
                });
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Welcome, ${adminUser.email}! Admin Mode Active'),
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
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('Sign Out'),
                    subtitle: const Text('Leave admin mode'),
                    onTap: () async {
                      Navigator.pop(context); // Close drawer
                      final messenger = ScaffoldMessenger.of(context);
                      await signOutAdmin();
                      if (!mounted) return;
                      setState(() => _isAdminMode = false);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Signed out of admin mode.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
                
                // Pushes the version text down to the very bottom like a footer
                const Spacer(),
                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _appVersion.isEmpty ? 'Version -' : 'Version $_appVersion',
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
                            height: previewHeight, 
                            width: double.infinity,
                            fit: BoxFit.cover,
                            alignment: Alignment(0.0, previewAlignmentY),
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: previewHeight,
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
                                      value: previewHeight.clamp(80.0, 300.0),
                                      min: 80.0,
                                      max: 300.0,
                                      divisions: 22,
                                      onChanged: (double val) => setState(() => _dragHeight = val.clamp(80.0, 300.0)),
                                      onChangeEnd: (double val) {
                                        setState(() => _dragHeight = null);
                                        _updateRemoteLayoutSettings(
                                          val.clamp(80.0, 300.0),
                                          previewAlignmentY,
                                        );
                                      },
                                    ),
                                  ),
                                  Text("${previewHeight.round()}px"),
                                ],
                              ),
                              Row(
                                children: [
                                  const SizedBox(width: 80, child: Text("Vertical Pan:", style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(
                                    child: Slider(
                                      value: previewAlignmentY.clamp(-1.0, 1.0),
                                      min: -1.0,
                                      max: 1.0,
                                      divisions: 40,
                                      onChanged: (double val) => setState(() => _dragAlignmentY = val.clamp(-1.0, 1.0)),
                                      onChangeEnd: (double val) {
                                        setState(() => _dragAlignmentY = null);
                                        _updateRemoteLayoutSettings(
                                          previewHeight,
                                          val.clamp(-1.0, 1.0),
                                        );
                                      },
                                    ),
                                  ),
                                  Text(previewAlignmentY == 0.0 
                                      ? "Center" 
                                      : previewAlignmentY < 0 
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

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mp3_app/services/firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  static const String uploadRoute = '/upload';
  static const String libraryRoute = '/library';

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, dynamic>> _recentSongs = [];
  int? _currentlyPlayingIndex;

  @override
  void initState() {
    super.initState();
    _loadRecentSongs();
    _audioPlayer.playerStateStream.listen((playerState) {
      setState(() {}); // Trigger rebuild to update UI
      if (playerState.processingState == ProcessingState.completed) {
        _currentlyPlayingIndex = null;
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSongs() async {
    try {
      List<String> songUrls = await _storageService.listFiles('songs');
      List<Map<String, dynamic>> allSongs =
          await Future.wait(songUrls.map((url) async {
        Map<String, dynamic>? metadata =
            await _storageService.getFileMetadata(url);
        return {
          'url': url,
          'title': metadata?['customMetadata']?['title'] ?? 'Unknown Title',
          'artist': metadata?['customMetadata']?['artist'] ?? 'Unknown Artist',
          'uploadDate': metadata?['timeCreated'] ?? DateTime.now(),
        };
      }));
      allSongs.sort((a, b) =>
          (b['uploadDate'] as DateTime).compareTo(a['uploadDate'] as DateTime));
      setState(() {
        _recentSongs = allSongs.take(5).toList(); // Get the 5 most recent songs
      });
    } catch (e) {
      print('Error loading recent songs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading recent songs: $e')),
      );
    }
  }

  Future<void> _playSong(int index) async {
    try {
      if (_currentlyPlayingIndex == index) {
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.setUrl(_recentSongs[index]['url']);
        await _audioPlayer.play();
        _currentlyPlayingIndex = index;
      }
      setState(() {}); // Trigger rebuild to update UI
    } catch (e) {
      print('Error playing song: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing song: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Music'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_currentlyPlayingIndex != null) _buildNowPlayingCard(),
          const SizedBox(height: 20),
          _buildQuickActions(context),
          const SizedBox(height: 20),
          _buildRecentSongs(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, HomePage.uploadRoute);
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Library',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.deepPurple,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, HomePage.libraryRoute);
          }
        },
      ),
    );
  }

  Widget _buildNowPlayingCard() {
    final currentSong = _recentSongs[_currentlyPlayingIndex!];
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_note, color: Colors.deepPurple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Now Playing',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  currentSong['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentSong['artist'],
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_audioPlayer.playing ? Icons.pause : Icons.play_arrow,
                color: Colors.white),
            onPressed: () => _playSong(_currentlyPlayingIndex!),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
            context, Icons.upload, 'Upload', HomePage.uploadRoute),
        _buildActionButton(
            context, Icons.library_music, 'Library', HomePage.libraryRoute),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context, IconData icon, String label, String route) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, route),
          child: Icon(icon, color: Colors.deepPurple),
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(20),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.deepPurple)),
      ],
    );
  }

  Widget _buildRecentSongs() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recently Added',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _recentSongs.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _recentSongs.length,
                      itemBuilder: (context, index) {
                        final song = _recentSongs[index];
                        final isPlaying = _currentlyPlayingIndex == index &&
                            _audioPlayer.playing;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Icon(Icons.music_note, color: Colors.white),
                          ),
                          title: Text(song['title']),
                          subtitle: Text(song['artist']),
                          trailing: IconButton(
                            icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.deepPurple),
                            onPressed: () => _playSong(index),
                          ),
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

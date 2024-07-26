import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mp3_app/services/firestore.dart';
import 'package:rxdart/rxdart.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, dynamic>> _songs = [];
  int? _currentlyPlayingIndex;

  @override
  void initState() {
    super.initState();
    _loadSongs();
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

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.bufferedPositionStream,
        _audioPlayer.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  Future<void> _loadSongs() async {
    try {
      List<String> songUrls = await _storageService.listFiles('songs');
      _songs = await Future.wait(songUrls.map((url) async {
        Map<String, dynamic>? metadata =
            await _storageService.getFileMetadata(url);
        return {
          'url': url,
          'title': metadata?['customMetadata']?['title'] ?? 'Unknown Title',
          'artist': metadata?['customMetadata']?['artist'] ?? 'Unknown Artist',
          'uploadDate': metadata?['timeCreated'] ?? DateTime.now(),
        };
      }));
      // Sort songs by upload date, most recent first
      _songs.sort((a, b) =>
          (b['uploadDate'] as DateTime).compareTo(a['uploadDate'] as DateTime));
      setState(() {});
    } catch (e) {
      print('Error loading songs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading songs: $e')),
        );
      }
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
        await _audioPlayer.setUrl(_songs[index]['url']);
        await _audioPlayer.play();
        _currentlyPlayingIndex = index;
      }
      setState(() {}); // Trigger rebuild to update UI
    } catch (e) {
      print('Error playing song: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing song: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _songs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      final song = _songs[index];
                      final isPlaying = _currentlyPlayingIndex == index &&
                          _audioPlayer.playing;
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Icon(Icons.music_note, color: Colors.white),
                          ),
                          title: Text(song['title'],
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(song['artist']),
                          trailing: IconButton(
                            icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.deepPurple),
                            onPressed: () => _playSong(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_currentlyPlayingIndex != null) _buildNowPlayingWidget(),
        ],
      ),
    );
  }

  Widget _buildNowPlayingWidget() {
    final currentSong = _songs[_currentlyPlayingIndex!];
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.deepPurple.shade50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.music_note, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(currentSong['title'],
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(currentSong['artist'], style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon:
                    Icon(_audioPlayer.playing ? Icons.pause : Icons.play_arrow),
                onPressed: () => _playSong(_currentlyPlayingIndex!),
              ),
            ],
          ),
          StreamBuilder<PositionData>(
            stream: _positionDataStream,
            builder: (context, snapshot) {
              final positionData = snapshot.data;
              return LinearProgressIndicator(
                value: positionData?.position.inMilliseconds.toDouble() ??
                    0.0 /
                        (positionData?.duration.inMilliseconds.toDouble() ??
                            1.0),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

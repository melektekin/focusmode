import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  } catch (e) {
    debugPrint("SystemChrome web hatası: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NextGen Pomodoro',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFFFF6584),
          surface: Color(0xFF1E1E2E),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const PomodoroScreen(),
    );
  }
}

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  late TextEditingController _urlController;
  late YoutubePlayerController _youtubeController;

  Timer? _timer;
  int _selectedMinutes = 25;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isVideoReady = false;
  bool _isBreakTime = false;

  final List<int> _minuteOptions = [10, 20, 25, 30, 40, 50, 60, 90];

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();

    _youtubeController = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: true,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _youtubeController.close();
    _urlController.dispose();
    super.dispose();
  }

  String? _convertUrlToId(String url) {
    if (url.trim().isEmpty) return null;
    final RegExp regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
    );
    final match = regExp.firstMatch(url);
    return (match != null && match.group(7)!.length == 11)
        ? match.group(7)
        : null;
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    if (!_isVideoReady && _urlController.text.isNotEmpty) {
      _loadVideo(_urlController.text);
    }

    setState(() {
      _isRunning = true;
      _isBreakTime = false;
    });

    _youtubeController.pauseVideo();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();

        setState(() {
          _isRunning = false;
          _isBreakTime = true;
        });

        _youtubeController.playVideo();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mola vakti! Video başlıyor..."),
            backgroundColor: Color(0xFF6C63FF),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _pauseTimer();
    _youtubeController.pauseVideo();
    setState(() {
      _remainingSeconds = _selectedMinutes * 60;
      _isBreakTime = false;
    });
  }

  void _selectTime(int minutes) {
    setState(() {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _isBreakTime = false;
    });
    if (_isRunning) _pauseTimer();
  }

  void _loadVideo(String url) {
    FocusScope.of(context).unfocus();

    String? videoId = _convertUrlToId(url);

    if (videoId != null) {
      _youtubeController.loadVideoById(videoId: videoId);
      _youtubeController.cueVideoById(videoId: videoId);

      setState(() {
        _isVideoReady = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Video Hazırlandı. Odaklanma bitince başlayacak."),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hata: Geçersiz YouTube Linki")),
      );
    }
  }

  String get _timerString {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (_selectedMinutes == 0) return 0;
    return _remainingSeconds / (_selectedMinutes * 60);
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 100;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: isKeyboardOpen ? 2 : 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isKeyboardOpen) ...[
                        Text(
                          _isBreakTime ? "MOLA ZAMANI ☕" : "FOCUS MODE",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: CircularProgressIndicator(
                              value: _progress,
                              strokeWidth: 8,
                              valueColor: AlwaysStoppedAnimation(
                                _isBreakTime
                                    ? const Color(0xFFFF6584)
                                    : const Color(0xFF6C63FF),
                              ),
                              backgroundColor: Colors.white10,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _timerString,
                                style: const TextStyle(
                                  fontSize: 60,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: _toggleTimer,
                                icon: Icon(
                                  _isRunning ? Icons.pause : Icons.play_arrow,
                                ),
                                label: Text(_isRunning ? "Durdur" : "Başla"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!isKeyboardOpen) const SizedBox(height: 30),
                      if (!isKeyboardOpen)
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _minuteOptions.length,
                            itemBuilder: (context, index) {
                              int minutes = _minuteOptions[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: ChoiceChip(
                                  label: Text('$minutes\''),
                                  selected: _selectedMinutes == minutes,
                                  onSelected: (_) => _selectTime(minutes),
                                  selectedColor: const Color(0xFF6C63FF),
                                  backgroundColor: Colors.white10,
                                  labelStyle: TextStyle(
                                    color: _selectedMinutes == minutes
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _urlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white10,
                        hintText: "YouTube Linki...",
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.link, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: _urlController.clear,
                        ),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) _loadVideo(value);
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_urlController.text.isNotEmpty) {
                                _loadVideo(_urlController.text);
                              }
                            },
                            icon: const Icon(Icons.upload),
                            label: const Text("Video Yükle"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6584),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        IconButton(
                          onPressed: _resetTimer,
                          icon: const Icon(Icons.refresh),
                          iconSize: 28,
                          color: const Color(0xFF6C63FF),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  color: Colors.black,
                  child: YoutubePlayer(
                    controller: _youtubeController,
                    aspectRatio: 16 / 9,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

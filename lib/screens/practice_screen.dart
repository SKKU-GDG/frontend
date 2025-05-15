import 'dart:io';  // File 때문에 import 했지만, Web 분기 내부에서만 사용
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;  // 추가
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'result_screen.dart';

import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class PracticeScreen extends StatefulWidget {
  final String category;
  const PracticeScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  bool _isSessionActive = false; // 녹음 or 녹화 중인지 표시
  Timer? _sessionTimer; // 8초 타이머
  
  bool isVoiceMode = true; // 음성 인식 모드

  late TextEditingController _customController;  // 여기!


  // recorder
  FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();

  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  XFile? _videoFile;

  // 동적으로 상황별 문장 설정
  late String _prompt;

  final Map<String, String> promptMap = {
    'Psychiatry': "I’ve been having trouble sleeping.",
    'Medical Treatment': "My stomach really hurts.",
    'Pharmacy': "My throat hurts and I have a cough.",
    'Custom': "Your voice matters,\nno matter how it is heard.",
  };



  @override
  void initState() {
    super.initState();

    // Web이면 카메라 초기화 아예 안 함
    if (!kIsWeb) {
      _initCameras();
      _initRecorder();
    }
    _prompt =
        promptMap[widget.category] ??
        "Your voice matters,\nno matter how it is heard.";
    
    if (widget.category == 'Custom') {
      _customController = TextEditingController(text: _prompt);
    }
  }

  // Future<void> _initSpeech() async {
  //   _speech = stt.SpeechToText();

  //   _speechEnabled = await _speech.initialize();
  //   if (_speechEnabled) {
  //     print('Speech-to-Text initialized successfully');
  //   } else {
  //     print('Speech-to-Text initialization failed');
  //   }


  //   // (선택) 사용 가능한 로케일 목록 중 en_US 가 있으면 그걸 쓰도록 설정
  //   final locales = await _speech.locales();
  //   final english = locales.firstWhere(
  //   (l) => l.localeId.startsWith('en'),
  //   orElse: () => locales.first,
  //   );
  //   _localeId = english.localeId;
  //   setState(() {});
  // }

  Future<void> _initRecorder() async {
    await Permission.microphone.request();
    await _audioRecorder.openRecorder();
  }

  Future<void> _initCameras() async {
    // 모바일(Android/iOS)인 경우에만 실행
    if (kIsWeb) return;

    await Permission.camera.request();
    _cameras = await availableCameras();
    
    if (_cameras!.isNotEmpty) {
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras![0], // 없으면 기본 첫 번째 카메라 사용
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      setState(() {});
    }
  }

  void _startListening() async {
    try {
      // 녹음 시작
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String path = '${appDocDir.path}/audio_file.aac';
      
      await _audioRecorder.startRecorder(toFile: path);
      
      setState(() {
        _isSessionActive = true;  // 세션 상태 업데이트
      });

      // // 8초 후 자동으로 stop을 호출
      // Timer(const Duration(seconds: 8), () {
      //   _stopListening();
      // });
    } 
    catch (e) {
      print("Error during recording: $e");
      return;
    }
  }

Future<void> _stopListening() async {
  try {
    if (_audioRecorder.isRecording == true) {
      await _audioRecorder.stopRecorder();
    }

    _sessionTimer?.cancel();

    setState(() {
      _isSessionActive = false;
    });

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String path = '${appDocDir.path}/audio_file.aac';

    final String? audioFilePath = path;

    // 결과 화면으로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          category: widget.category,
          originalText: _prompt,
          userText:"[AI is analyzing your pronun]",
          isVoiceMode: true,
          videoFilePath: audioFilePath ?? '',
        ),
      ),
    );
  } catch (e) {
    print("Error stopping the recorder: $e");
  }
}

  // void _startListening() async {
  //   if (!_speechEnabled) return;

  //   await _speech.listen(
  //     localeId: _localeId,
  //     onDevice: true,           // ← 여기로 이동
      
  //     onResult: (val) {
  //       setState(() {
  //       _lastWords = val.recognizedWords;
  //       print('Recognized Words: $_lastWords');
  //       });
  //     },
  //   );
  // }


  // void _stopListening() async {
  //   await _speech.stop();
  //   _sessionTimer?.cancel();
  //   setState(() => _isSessionActive = false);  // 추가
    
  //   print('STT Result: $_lastWords');

  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => ResultScreen(
  //         category: widget.category,
  //         originalText: _prompt,
  //         userText: _lastWords,
  //         isVoiceMode: true,
  //         videoFilePath: ""
  //         //aiGuideAsset: 'assets/videos/ai_guide.mp4', // AI 가이드 비디오(없으면 null)
  //               ),
  //     ),
  //   );
  // }

  // 녹화 시작
  Future<void> _startVideoRecording() async {
    if (kIsWeb) return;  // Web에선 스킵
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (!_cameraController!.value.isRecordingVideo) {
      await _cameraController!.startVideoRecording();
    }
  }

  // 녹화 종료
  void _stopVideoRecording() async {
    if (kIsWeb) {
      // Web일 때는 간단히 결과 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            category: widget.category,
            originalText: _prompt,
            userText: '[AI is analyzing your pronun]',
            isVoiceMode: false,
            videoFilePath: ""
          ),
        ),
      );
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) {
      return;
    }
    XFile file = await _cameraController!.stopVideoRecording();
    
    _sessionTimer?.cancel();
    setState(() {
      _isSessionActive = false;
      _videoFile = file;
    });

    print("Audio saved at: ${file.path}");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          category: widget.category,
          originalText: _prompt,
          userText: "[AI is analyzing your pronun]",
          isVoiceMode: false,
          videoFilePath: file.path
        ),
      ),
    );
  }
 
  // 3) 여기에 _startSession() 추가
  /// VOICE 모드면 STT 시작, VIDEO 모드면 녹화 시작 후
  /// 10초 뒤 _stopListening/_stopVideoRecording 을 호출합니다.
void _startSession() async {
  if (_isSessionActive) {
    if (isVoiceMode) {
      _stopListening();
    } else {
      _stopVideoRecording();
    }
  }
  else{
    setState(() {
      _isSessionActive = true;
    });

    if (isVoiceMode) {
      _startListening();
    } else {
      _startVideoRecording();
    }

    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(seconds: 8), () {
      if (isVoiceMode) {
        _stopListening();
      } else {
        _stopVideoRecording();
      }
    });
  }
}

  // void _goToResult({
  // required String originalText,
  // required String userText,
  // required bool isVoiceMode,
  // String? aiGuideAsset,
  // }) {
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => ResultScreen(
  //         category: widget.category,
  //         originalText: originalText,
  //         userText: userText,
  //         isVoiceMode: isVoiceMode,

  //         videoFilePath: ""
  //         //aiGuideAsset: aiGuideAsset,
  //       ),
  //     ),
  //   );
  // }

  @override
  void dispose() {
    //_speech.stop();
    _audioRecorder.closeRecorder();
    _cameraController?.dispose();
    if (widget.category == 'Custom') {
      _customController.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        centerTitle: true,
        backgroundColor: const Color(0xFFFAF7FF),
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFFAF7FF),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('발음해 보세요!', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: widget.category == 'Custom'
              ? TextField(
                  controller: _customController,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Type your custom prompt here",
                  ),
                  onChanged: (value) {
                    _prompt = value; // 실시간으로 _prompt 업데이트
                  },
                )
              : Text(
                  _prompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
          ),
          const SizedBox(height: 24),
           GestureDetector(
   onTap: _startSession,  // ← 여기 한 줄로 대체!
   child: CircleAvatar(
     radius: 48,
     backgroundColor: Colors.grey.shade200,
     child: Icon(
      _isSessionActive
        ? Icons.stop
        : (isVoiceMode ? Icons.mic : Icons.videocam),
       size: 40,
       color: Colors.black54,
     ),
   ),
),
          const SizedBox(height: 28),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor:
                          isVoiceMode ? const Color(0xFFE7E0F8) : null,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(30),
                        ),
                      ),
                    ),
                    onPressed: () => setState(() => isVoiceMode = true),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isVoiceMode) const Icon(Icons.check, size: 18),
                        const SizedBox(width: 6),
                        const Text('VOICE', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor:
                          !isVoiceMode ? const Color(0xFFE7E0F8) : null,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(30),
                        ),
                      ),
                    ),
                    onPressed: () => setState(() => isVoiceMode = false),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isVoiceMode) const Icon(Icons.check, size: 18),
                        const SizedBox(width: 6),
                        const Text('VIDEO', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

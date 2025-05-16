import 'dart:io';  
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;  
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
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
  bool _isSessionActive = false; 
  Timer? _sessionTimer; 
  
  bool isVoiceMode = true; 

  late TextEditingController _customController;  

  // recorder
  FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  XFile? _videoFile;

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


  Future<void> _initRecorder() async {
    await Permission.microphone.request();
    await _audioRecorder.openRecorder();
  }

  Future<void> _initCameras() async {
    if (kIsWeb) return;

    await Permission.camera.request();
    _cameras = await availableCameras();
    
    if (_cameras!.isNotEmpty) {
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras![0], 
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
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String path = '${appDocDir.path}/audio_file.aac';
      
      await _audioRecorder.startRecorder(toFile: path);
      
      setState(() {
        _isSessionActive = true;  
      });

    
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


  Future<void> _startVideoRecording() async {
    if (kIsWeb) return;  
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (!_cameraController!.value.isRecordingVideo) {
      await _cameraController!.startVideoRecording();
    }
  }

  void _stopVideoRecording() async {
    if (kIsWeb) {
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

    Fluttertoast.showToast(
      msg: "Maximum recording time is 8 seconds.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

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



  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    _cameraController?.dispose();
    if (widget.category == 'Custom') {
      _customController.dispose();
    }

    super.dispose();
  }

  Widget _buildCameraPreviewUI() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final previewSize = _cameraController!.value.previewSize!;

    final width = previewSize.width < previewSize.height ? previewSize.width : previewSize.height;
    final height = previewSize.width < previewSize.height ? previewSize.height : previewSize.width;
    final aspectRatio = width / height;

    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: _stopVideoRecording,
              child: const Icon(Icons.stop),
            ),
          ),
        ),
      ],
    );
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
      body: (_isSessionActive && !isVoiceMode)
        ? _buildCameraPreviewUI()
        : Column(
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
                    _prompt = value;
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
              onTap: _startSession, 
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

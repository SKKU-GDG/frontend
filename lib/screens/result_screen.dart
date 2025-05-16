// lib/screens/result_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:chewie/chewie.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

//test
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';

class ResultScreen extends StatefulWidget {
  final String category;
  final String originalText;
  final String userText;      
  final bool isVoiceMode;     
  
  final String videoFilePath;
  
  const ResultScreen({
    Key? key,
    required this.category,
    required this.originalText,
    required this.userText,
    required this.isVoiceMode,
    required this.videoFilePath,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  VideoPlayerController? _userVideoCtr;

  String? _aiSolution;
  bool   _loadingAI = false;
  
  String userPronun = "";
  
  VideoPlayerController? _aiVideoCtr;
  

  @override
  void initState() {
    super.initState();


    if (!widget.isVoiceMode) {
      _userVideoCtr = VideoPlayerController.file(File(widget.videoFilePath))
        ..initialize().then((_) => setState(() {}));

      _fetchAISolution();
      _getAIGuideVideo();
    }

    if (widget.isVoiceMode) {
      
       _fetchAISolution();
      _getAIGuideVideo();
    }
  }

  Future<void> _sendAudioToApi(File audioFile) async {
    if (!audioFile.existsSync()) {
      print('Could not find the audio file'); 
      return;
    }
    
    final uri = Uri.parse('https://f680-203-252-33-7.ngrok-free.app/upload'); 
    final request = http.MultipartRequest('POST', uri);

    final fileName = basename(audioFile.path);

    String contentType;
    if (fileName.endsWith('.aac')) {
      contentType = 'audio/aac';
    } else if (fileName.endsWith('.mp3')) {
      contentType = 'audio/mpeg';
    } else {
      contentType = 'application/octet-stream';  
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ),
    );

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        print('upload success: $respStr');

        final Map<String, dynamic> jsonResponse = json.decode(respStr);
        userPronun = jsonResponse['transcription'] ?? '-';

        print('userText : $userPronun');
      } 
      else {
        print('can not upload: ${response.statusCode}');
      }
    } catch (e) {
      print('error: $e'); 
    }
  }

  @override
  void dispose() {
    _userVideoCtr?.dispose();
    _aiVideoCtr?.dispose();
    super.dispose();
  }

  Future<void> _getAIGuideVideo() async {
    final url = Uri.parse("https://f680-203-252-33-7.ngrok-free.app/get-video");

    http.Response response;

    try {
      if (widget.isVoiceMode) {
        final request = http.MultipartRequest('POST', url);
        request.files.add(
          http.MultipartFile.fromString('text', widget.originalText),
        );
        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        final videoFile = File(widget.videoFilePath); 
        final request = http.MultipartRequest('POST', url);
        request.fields['text'] = widget.originalText;
        request.files.add(
          await http.MultipartFile.fromPath('video_file', videoFile.path),
        );
        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      }

      if (response.statusCode == 200) {
        final Uint8List videoBytes = response.bodyBytes;

        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/ai_guide_video.mp4';
        final file = File(filePath);
        await file.writeAsBytes(videoBytes);

        _aiVideoCtr = VideoPlayerController.file(file);
        await _aiVideoCtr!.initialize();

        setState(() {
          _aiVideoCtr!.play();
        });
      } else {
        print("❌ Failed to load AI video: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching AI guide video: $e");
    }
  }



  Future<String> fetchPronunciationAdvice(String original, String user) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';  
    if (apiKey.isEmpty) {
      return 'Error: API Key not found in .env';
    }

    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

    final headers = {
      'Content-Type': 'application/json',
    };

    final prompt = '''
  I want you to act as a pronunciation coach.

  Here's the target sentence:
  Original: "$original"

  Here's the user's pronunciation attempt:
  UserPronunciation: "$user"

  Please identify the pronunciation differences between the user's attempt and the original. For each mispronounced word or phoneme, provide:
  1. The correct phonetic transcription (IPA)
  2. A comparison with the user's mispronunciation
  3. Specific articulation tips — including mouth shape, tongue position, voicing, and airflow
  4. Optional visualizations or example comparisons, if useful

  The goal is to help the user pronounce the sentence naturally. Be clear and educational, using simple explanations if possible.
  ''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    });

    final response = await http.post(
      uri,
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final text = json['candidates'][0]['content']['parts'][0]['text'];
      return text;
    } else {
      return 'Error: ${response.statusCode} - ${response.body}';
    }
  }

  Future<void> _fetchAISolution() async {
    await _sendAudioToApi(File(widget.videoFilePath));


    setState(() => _loadingAI = true);
    final advice = await fetchPronunciationAdvice(
      widget.originalText,
      userPronun
    );
    setState(() {
      _aiSolution = advice;
      _loadingAI  = false;
    });
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const Text(
              'Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage:
                    AssetImage('assets/images/avatar_placeholder.png'),
              ),
            ),
            const SizedBox(height: 16),

            // correct pronun
            Row(
              children: [
                _tag('correct pronun'),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.originalText,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // your pronun
            Row(
              children: [
                _tag('your pronun'),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      userPronun.isEmpty 
                        ? '[AI is analyzing your voice]' 
                        : userPronun,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const Text(
              'AI Solution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            
            if (_loadingAI)
              Center(child: CircularProgressIndicator())
            else if (_aiSolution != null)
              _boxedText(_aiSolution!)
            else
              _boxedText('Loading AI'),

            const SizedBox(height: 24),
            if (widget.isVoiceMode) ...[
              const Text(
                'AI Pronunciation Guide',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildVideoPlayer(_aiVideoCtr),
            ] else ...[
              const Text(
                'Your Pronunciation Video',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildVideoPlayer(_userVideoCtr),
              const SizedBox(height: 24),
              const Text(
                'AI Pronunciation Guide',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildVideoPlayer(_aiVideoCtr),
            ],

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3FD3),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Back to Menu',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      );
  
  Widget _boxedText(String t) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: MarkdownBody(  
      data: t,  
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(fontSize: 14), 
      ),
    ),
  );

  Widget _buildPlaceholder() => Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFFE7E0F8)),
          ),
        ),
      );

  Widget _buildVideoPlayer(VideoPlayerController? ctr) {
    if (ctr == null || !ctr.value.isInitialized) return _buildPlaceholder();
    
    ctr.setVolume(0.0);
    final size = ctr.value.size;
    final double width = size.width < size.height ? size.width : size.height;
    final double height = size.width < size.height ? size.height : size.width;
    final aspectRatio = width / height;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Chewie(
        controller: ChewieController(
          videoPlayerController: ctr,
          autoPlay: true, 
          looping: true, 
          aspectRatio: aspectRatio,
          allowPlaybackSpeedChanging: true, 
        ),
      ),
    );
  }

}

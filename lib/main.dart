import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart' as audio;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:social_media_recorder/audio_encoder_type.dart';
import 'package:social_media_recorder/screen/social_media_recorder.dart';
import 'package:test_record/home%20new.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: RecordingScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FlutterSoundRecorder flutterSound = FlutterSoundRecorder();
  bool isRecorderReady = false;
  final audioPlayer = audio.AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  String filePath = '';
  bool showPlayer = false;
  bool isRecording = false;
  String? audioPath;
  String transcription = '';
  // final audioRecord = AudioRecorder();

  // final record = AudioRecorder();

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [
      if (duration.inHours > 0) hours,
      minutes,
      seconds,
    ].join(':');
  }

  @override
  void initState() {
    super.initState();
    initRecorder();

    /// Listen to states: playing, paused, stopped
    audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.isPlaying;
      });
    });

    /// Listen to audio duration

    // audioRecord = AudioRecorder();
    // audioPlayer = AudioPlayer();
  }

  @override
  dispose() {
    audioPlayer.dispose();
    // audioRecord.dispose();
    super.dispose();
  }

  Future initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw 'Microphone permission not granted';
    }
    await flutterSound.openRecorder();
    isRecorderReady = true;
    flutterSound.setSubscriptionDuration(const Duration(milliseconds: 500));
  }

  Future record() async {
    try {
      if (!isRecorderReady) return;
      await flutterSound.startRecorder(
        toFile: 'audio',
        codec: Codec.mp3,
      );
    } catch (e) {
      print('Error recording: $e');
    }
  }

  Future stop() async {
    if (!isRecorderReady) return;
    final path = await flutterSound.stopRecorder();
    final file = File(path!);
    debugPrint('File length: ${await file.length()}');
    debugPrint('path: $path file: $file');
    debugPrint('fille: $file file: $file');
    convertSpeechToText('$path.mp3');
  }

  Future<String> convertSpeechToText(String filePath) async {
    const apiKey = 'api key whisper';
    try {
      if (filePath.isNotEmpty) {
        var url = Uri.https("api.openai.com", "v1/audio/transcriptions");
        var request = http.MultipartRequest('POST', url);
        request.headers.addAll(({"Authorization": "Bearer $apiKey"}));
        request.fields["model"] = 'whisper-1';
        request.fields["language"] = "en";
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
        var response = await request.send();
        var newresponse = await http.Response.fromStream(response);

        print('@res ${newresponse.body}');
        print('@res ${newresponse.statusCode}');
        if (newresponse.statusCode == 200) {
          setState(() {
            transcription = json.decode(newresponse.body)['text'];
          });
          print('Transcription: $transcription');
          return transcription;
        } else {
          print('Error: ${newresponse.statusCode}');
          print('Response: ${newresponse.body}');
        }
        return transcription;
      }
      return transcription;
    } catch (e) {
      print('Error: $e');
    }
    return '';
  }

  Future<void> startRecording() async {
    try {
      // bool? hasPermission = await audioRecord.hasPermission();
      // if (hasPermission) {
      //   final appDocDir = await getApplicationDocumentsDirectory();
      //   filePath = '${appDocDir.path}/myFile.mp3';

      //   await audioRecord.start(const RecordConfig(), path: filePath);
      //   print('@Recording started');
      //   print('@filepath$filePath');
      //   setState(() {
      //     showPlayer = false;
      //   });
      // } else {
      //   print('Permission denied');
      // }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      // final path = await audioRecord.stop();
      print('@Recording stopped');
      // print('@filepath path$path');
      print('@filepath$filePath');
      // final audioFile = File(path!);
      // transcribeAudio(path);
      convertSpeechToText(filePath);

      setState(() {
        showPlayer = true;
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> playRecording(paths) async {
    try {
      audio.Source urlSource = audio.UrlSource(paths);
      await audioPlayer.play(urlSource);
    } catch (e) {
      print('Error playing Recording : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recording and Transcription'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showPlayer)
              Container(
                margin: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    playRecording(filePath);
                  },
                  child: const Text('Play'),
                ),
              ),
            ElevatedButton(
              onPressed: startRecording,
              child: const Text('Start'),
            ),
            ElevatedButton(
              onPressed: stopRecording,
              child: const Text('Stop'),
            ),
            StreamBuilder<RecordingDisposition>(
              stream: flutterSound.onProgress,
              builder: (context, snapshot) {
                final duration =
                    snapshot.hasData ? snapshot.data!.duration : Duration.zero;
                return Text('${duration.inSeconds} s');
              },
            ), // StreamBuilder
            ElevatedButton(
                onPressed: () async {
                  if (flutterSound.isRecording) {
                    await stop();
                  } else {
                    await record();
                  }
                },
                child: Icon(flutterSound.isRecording ? Icons.stop : Icons.mic)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(formatTime(position)),
              Text(formatTime(duration)),
            ]),
            CircleAvatar(
                radius: 35,
                child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                    ), // Icon
                    iconSize: 50,
                    onPressed: () async {
                      if (isPlaying) {
                        await audioPlayer.pause();
                      } else {
// Source urlSource = UrlSource(paths);

// await audioPlayer.play();}
                      }
                    }) // IconButton
                ),
            SocialMediaRecorder(
              // maxRecordTimeInSecond: 5,
              startRecording: () {
                // function called when start recording
              },
              stopRecording: (time) {
                // function called when stop recording, return the recording time
              },
              sendRequestFunction: (soundFile, time) {
                print("the current path is ${soundFile.path}");
              },
              encode: AudioEncoderType.AAC,
            ),
            // CircleAvatar
            Text('Transcription: $transcription'),
          ],
        ),
      ),
    );
  }
}
/* Future<void> transcribeAudio(File audioFile) async {
    const apiKey = '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';
    const apiUrl = 'https://api.openai.com/v1/audio/transcriptions';

    // List<int> audioBytes = File(filePath).readAsBytesSync();
    // String base64Audio = base64Encode(audioBytes);

    try {
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl))
        ..headers['Authorization'] = 'Bearer $apiKey'
        ..files.add(http.MultipartFile(
            'file', audioFile.readAsBytes().asStream(), audioFile.lengthSync(),
            filename: basename(audioFile.path)))
        ..fields['model'] = 'whisper-1';

      final response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        setState(() {
          transcription = jsonDecode(response.body)['transcription'];
        });
        print('Transcription: $transcription');
      } else {
        print('Error: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
 */
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'app_log.dart';
import 'get_recording_path.dart';

class CallMonitor {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;

  Future<void> initializeRecorder() async {
    try {
      if (!_recorder.isRecording) {
        await _recorder.openRecorder();
        _isRecorderInitialized = true;
      }
    } catch (e) {
      String dateNow = DateTime.now().toString();
      if (kDebugMode) {
        print('CallMonitor Error initializing recorder: $e');
      }
      await logChomik('$dateNow: CallMonitor Error initializing recorder: $e');
    }
  }

  Future<void> startRecording(String fileName) async {
    try {
      String dateNow = DateTime.now().toString();
      await logChomik('$dateNow: CallMonitor startRecording');

      if (fileName.isEmpty) {
        fileName = 'recording';
      }
      // Upewnij się, że nagrywarka jest zainicjalizowana
      await initializeRecorder();
      dateNow = DateTime.now().toString();
      await logChomik('$dateNow: CallMonitor initializeRecorder');

      String recordingPath = await getRecordingPath();
      //String path = '${Directory.systemTemp.path}/$fileName.aac';
      String path = '$recordingPath/${fileName.replaceAll('+', '')}.aac';
      dateNow = DateTime.now().toString();
      await logChomik('$dateNow: CallMonitor path:$path');

      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
      );
      dateNow = DateTime.now().toString();
      await logChomik('$dateNow: CallMonitor Recording started');
    } catch (e) {
      String dateNow = DateTime.now().toString();
      await logChomik('$dateNow: CallMonitor Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    String dateNow = DateTime.now().toString();
    await logChomik('$dateNow: CallMonitor stopRecording');
    try {
      await _recorder.stopRecorder();
      dateNow = DateTime.now().toString();
      await logChomik('$dateNow: CallMonitor Recording stopped and saved');
    } catch (e) {
      String dateNow = DateTime.now().toString();
      await logChomik('$dateNow: CallMonitor Error stopping recording: $e');
    }
  }

  Future<void> disposeRecorder() async {
    String dateNow = DateTime.now().toString();
    await logChomik('$dateNow: disposeRecorder');
    if (_isRecorderInitialized) {
      await _recorder.closeRecorder();
      _isRecorderInitialized = false;
    }
  }
}

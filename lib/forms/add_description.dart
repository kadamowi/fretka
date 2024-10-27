import 'dart:async';
import 'dart:convert';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../api/app_log.dart';

class DescriptionPage extends StatefulWidget {
  final String callStart;
  const DescriptionPage({super.key, required this.callStart});

  @override
  State<DescriptionPage> createState() => _DescriptionPageState();
}

class _DescriptionPageState extends State<DescriptionPage> {
  final GlobalKey<FormState> _formStateKey = GlobalKey<FormState>();
  final baseUrl = Uri.parse('https://ricco.azurewebsites.net/api/desc');
  final headers = {"Content-Type": "application/json", "App": "Fretka"};
  int _id = 0;
  String _description = "";
  bool _isLoading = true;
  bool _hasError = false;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  TextEditingController voiceInput = TextEditingController();
  TextEditingController textInput = TextEditingController();

  Future<void> getDescription() async {
    String dateNow = DateTime.now().toString();
    try {
      Uri uriGet = Uri.parse('$baseUrl/${widget.callStart}');
      var respGet = await http.get(uriGet, headers: headers);
      String jsonResponse = respGet.body;
      if (respGet.statusCode != 200) {
        await logChomik('$dateNow: getDescription Error StatusCode:${respGet.statusCode}');
        if (kDebugMode) {
          print('$dateNow: getDescription Error StatusCode:${respGet.statusCode}');
        }
        setState(() {
          _hasError = true;
        });
        return;
      }
      Map<String, dynamic> decoded = json.decode(jsonResponse);
      setState(() {
        _id = decoded['id'];
        textInput.text = decoded['userDescription'];
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      await logChomik('$dateNow: sendCalls Error:$e');
      if (kDebugMode) {
        print('$dateNow: sendCalls Error:$e');
      }
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }
  }

  Future<void> setDescription() async {
    String dateNow = DateTime.now().toString();
    try {
      Uri uriPut = Uri.parse('$baseUrl/$_id');
      var respPut = await http.put(
        uriPut,
        headers: headers,
        body: jsonEncode({
          "userDesc": _description,
        }),
      );
      if (respPut.statusCode != 200) {
        await logChomik('$dateNow: setDescription Error StatusCode:${respPut.statusCode}');
      }
    } catch (e) {
      await logChomik('$dateNow: setDescription Error:$e');
    }
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  @override
  void initState() {
    _initSpeech();
    getDescription();
    super.initState();
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    _speechToText.statusListener = (String status) {
      if (status == "done") {
        _stopListening();
      }
    };

    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      if (textInput.text.isEmpty) {
        textInput.text = voiceInput.text;
      } else {
        textInput.text = '${textInput.text} ${voiceInput.text}';
      }
      voiceInput.clear();
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      voiceInput.text = result.recognizedWords;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(title: const Text('Opis')),
      resizeToAvoidBottomInset: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Błąd pobierania danych', style: TextStyle(color: Colors.red)),
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _hasError = false;
                          });
                          getDescription();
                        },
                        child: const Text('Spróbuj ponownie')),
                  ],
                ))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Form(
                        key: _formStateKey,
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rozpoznanie głosowe',
                                    style: Theme.of(context).textTheme.headlineMedium,
                                  ),
                                  Visibility(
                                    visible: _speechEnabled,
                                    child: AvatarGlow(
                                      startDelay: const Duration(milliseconds: 1000),
                                      animate: !_speechToText.isNotListening, //_speechEnabled,
                                      glowColor: Theme.of(context).primaryColor,
                                      glowShape: BoxShape.circle,
                                      duration: const Duration(milliseconds: 2000),
                                      repeat: true,
                                      child: IconButton(
                                        tooltip: 'Mów',
                                        icon: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
                                        iconSize: 30,
                                        onPressed: () {
                                          setState(() {
                                            _speechToText.isNotListening ? _startListening() : _stopListening();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              TextFormField(
                                controller: voiceInput,
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                minLines: 3,
                                textCapitalization: TextCapitalization.sentences,
                                readOnly: true,
                              ),
                              const SizedBox(height: 10.0),
                              Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Treść notatki',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                              ),
                              const SizedBox(height: 5.0),
                              TextFormField(
                                controller: textInput,
                                validator: (value) {
                                  if (value!.isEmpty && value.trim().isEmpty) {
                                    return 'Wprowadź opis';
                                  }
                                  return null;
                                },
                                onSaved: (value) => _description = value!.trim(),
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                minLines: 5,
                                textCapitalization: TextCapitalization.sentences,
                              ),
                              const SizedBox(height: 10.0),
                              SizedBox(
                                  child: ElevatedButton(
                                child: Text('Zapisz', style: Theme.of(context).textTheme.labelLarge),
                                onPressed: () {
                                  if (_formStateKey.currentState!.validate()) {
                                    _formStateKey.currentState!.save();
                                    setDescription();
                                    Navigator.pop(context);
                                  }
                                },
                              ))
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
    ));
  }
}

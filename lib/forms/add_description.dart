import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../api/description_api.dart';

class AddDescription extends StatefulWidget {
  final DescriptionType initialDescription;
  final ValueChanged<DescriptionType> onTextChanged;
  const AddDescription({super.key, required this.initialDescription, required this.onTextChanged});

  @override
  State<AddDescription> createState() => _AddDescriptionState();
}

class _AddDescriptionState extends State<AddDescription> with WidgetsBindingObserver {
  final GlobalKey<FormState> _formStateKey = GlobalKey<FormState>();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  //TextEditingController voiceInput = TextEditingController();
  TextEditingController textInput = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late String _description;

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // obserwuj cykl życia
    _initSpeech();
    setState(() {
      textInput.text = widget.initialDescription.description;
    });
    _startListening();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // przestań obserwować
    _focusNode.dispose();
    super.dispose();
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
        textInput.text = _description;
      } else {
        textInput.text = '${textInput.text} $_description';
      }
      _description = '';
      //voiceInput.clear();
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _description = result.recognizedWords;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
      if (kDebugMode) {
        print('didChangeAppLifecycleState: $state');
      }
      _saveNote();
    }
  }

  void _saveNote() {
    if (_formStateKey.currentState?.validate() ?? false) {
      _formStateKey.currentState!.save();
      widget.onTextChanged(DescriptionType(
        id: widget.initialDescription.id,
        description: textInput.text.trim(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          if (kDebugMode) {
            print('Zamknięcie krzyżykiem');
          }
          _saveNote();
        }
      },
      child: SafeArea(
          child: Scaffold(
        appBar: AppBar(title: const Text('Opis')),
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
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
                            _speechEnabled ? 'Rozpoznanie głosowe' : 'Wprowadź treść',
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
                      /*
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
                       */
                      TextFormField(
                        controller: textInput,
                        focusNode: _focusNode,
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
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      )),
    );
  }
}

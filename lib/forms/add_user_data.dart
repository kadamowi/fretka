import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPage extends StatefulWidget {
  final String ownerName;
  final String ownerNumber;
  const UserPage({super.key, required this.ownerName, required this.ownerNumber});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final GlobalKey<FormState> _formStateKey = GlobalKey<FormState>();
  static late SharedPreferences _preferences;

  String _ownerName = "";
  String _ownerNumber = "";

  @override
  void initState() {
    _ownerName = widget.ownerName;
    _ownerNumber = widget.ownerNumber;
    SharedPreferences.getInstance().then((value) {
      _preferences = value;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const Text('Dane użytkownika'),
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
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Nazwa użytkownika',
                        ),
                        initialValue: _ownerName,
                        validator: (value) {
                          if (value!.isEmpty && value.trim().isEmpty) {
                            return 'Wprowadź swoje inicjały';
                          }
                          return null;
                        },
                        onSaved: (value) => _ownerName = value!.trim(),
                        maxLength: 30,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Numer telefonu',
                        ),
                        initialValue: _ownerNumber,
                        validator: (value) {
                          if (value!.isEmpty && value.trim().isEmpty) {
                            return 'Wprowadź swoje numer telefonu';
                          }
                          if (value.length != 9) {
                            return 'Telefon musi posiadać 9 cyfr';
                          }
                          return null;
                        },
                        onSaved: (value) => _ownerNumber = value!.trim(),
                        maxLength: 9,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10.0),
                      SizedBox(
                          child: ElevatedButton(
                            child: Text('Zapisz',
                                style: Theme.of(context).textTheme.labelLarge),
                            onPressed: () {
                              if (_formStateKey.currentState!.validate()) {
                                _formStateKey.currentState!.save();
                                _preferences.setString('OwnerName', _ownerName);
                                _preferences.setString('OwnerNumber', _ownerNumber);
                                Navigator.pop(context);
                              }
                            },
                          )
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        )
    );
  }

}
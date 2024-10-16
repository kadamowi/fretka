import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../add_user_data.dart';
import '../api/calls_info.dart';
import '../api/user_info.dart';
import '../widgets/alert.dart';
import '../widgets/page_header.dart';
import '../widgets/theme_container.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  DateTime lastClickSend = DateTime(2024, 2, 1);

  @override
  void initState() {
    if (kDebugMode) {
      print('Profile -> initState');
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: <Widget>[
            const PageHeader(title: 'Profil użytkownika'),
            ThemedContainer(
              child: Column(
                children: [
                  Text('Użytkownik: $ownerName'),
                  Text('Telefon: $ownerNumber'),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UserPage(ownerName: ownerName, ownerNumber: ownerNumber)),
                            ).then((value) {
                              setState(() {
                                getUser();
                              });
                            });
                          },
                          child: Text('Zmiana danych', style: Theme.of(context).textTheme.labelLarge),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ThemedContainer(
              child: Column(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Center(child: Text('Operacje techniczne', style: Theme.of(context).textTheme.titleMedium)),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                            onPressed: () async {
                              final directory = await getApplicationDocumentsDirectory();
                              Share.shareXFiles([XFile('${directory.path}/chomik.log')], text: 'directory.path');
                            },
                            child: Text('Udostępnij log', style: Theme.of(context).textTheme.labelLarge)),
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (lastClickSend.difference(DateTime.now()).abs().inMinutes < 60) {
                              showAlertDialog(context, "Niedawno wysyłałeś ...");
                            } else {
                              sendCalls("Tech");
                              lastClickSend = DateTime.now();
                            }
                          },
                          child: Text('Wyślij wszystko', style: Theme.of(context).textTheme.labelLarge),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../api/app_log.dart';
import '../api/calls_info.dart';
import '../api/notes_api.dart';
import '../api/user_info.dart';
import '../forms/add_user_data.dart';
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
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  @override
  void initState() {
    _initPackageInfo();
    super.initState();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
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
                  Text('${_packageInfo.appName} wersja ${_packageInfo.buildNumber}'),
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
                      Visibility(
                        visible: !Platform.isWindows,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SizedBox(
                                  width: 150,
                                  child: ElevatedButton(
                                      onPressed: () async {
                                        final directory = await getApplicationDocumentsDirectory();
                                        final logFilePath = '${directory.path}/chomik.log';

                                        final file = File(logFilePath);

                                        if (await file.exists()) {
                                          await Share.shareXFiles(
                                            [XFile(logFilePath)],
                                            text: 'Zobacz logi z aplikacji Chomik.',
                                          );
                                        } else {
                                          if (kDebugMode) {
                                            print("Plik chomik.log nie istnieje.");
                                          }
                                        }
                                        //Share.shareXFiles([XFile('${directory.path}/chomik.log')], text: 'directory.path');
                                      },
                                      child: Text('Udostępnij log', style: Theme.of(context).textTheme.labelLarge)),
                                ),
                                SizedBox(
                                  width: 150,
                                  child: ElevatedButton(
                                      onPressed: () async {
                                        await deleteLogChomik();
                                        showAlertDialog(context, "Plik usunięty");
                                      },
                                      child: Text('Skasuj log', style: Theme.of(context).textTheme.labelLarge)),
                                ),
                              ],
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
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () {
                            updateNoteAfterSync('Profile send');
                          },
                          child: Text('Wyślij notatki', style: Theme.of(context).textTheme.labelLarge),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ThemedContainer(
                child: Column(
                  children: [
                    Center(child: Text('Operacje', style: Theme.of(context).textTheme.titleMedium)),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: logInfo.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                              decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey,
                                  ),
                                  borderRadius: BorderRadius.circular(20)),
                              margin: EdgeInsets.all(5),
                              padding: EdgeInsets.all(5),
                              child: ListTile(
                                title: Text(logInfo[index].key,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    )),
                                subtitle: Text(logInfo[index].value),
                              ));
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

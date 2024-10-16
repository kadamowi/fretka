import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences preferences;

String ownerName = "";
String ownerNumber = "";

void getUser() {
  var x = preferences.getString('OwnerName');
  if (x != null) {
    ownerName = x;
  }
  x = preferences.getString('OwnerNumber');
  if (x != null) {
    ownerNumber = x;
  }
}

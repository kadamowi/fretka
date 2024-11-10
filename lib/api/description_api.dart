import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_log.dart';

final baseUrl = Uri.parse('https://ricco.azurewebsites.net/api/desc');
final headers = {"Content-Type": "application/json", "App": "Fretka"};

class DescriptionType {
  int id;
  String description;

  DescriptionType({required this.id, required this.description});
}

Future<DescriptionType> getDescription(String callStart) async {
  String dateNow = DateTime.now().toString();
  try {
    Uri uriGet = Uri.parse('$baseUrl/$callStart');
    var respGet = await http.get(uriGet, headers: headers);
    String jsonResponse = respGet.body;
    if (respGet.statusCode != 200) {
      await logChomik('$dateNow: getDescription Error StatusCode:${respGet.statusCode}');
      return DescriptionType(id: 0, description: 'Error');
    }
    Map<String, dynamic> decoded = json.decode(jsonResponse);
    return DescriptionType(id: decoded['id'], description: decoded['userDescription']);
  } catch (e) {
    return DescriptionType(id: 0, description: e.toString());
  }
}

Future<void> setDescription(DescriptionType desc) async {
  String dateNow = DateTime.now().toString();
  try {
    Uri uriPut = Uri.parse('$baseUrl/${desc.id}');
    var respPut = await http.put(
      uriPut,
      headers: headers,
      body: jsonEncode({
        "userDesc": desc.description,
      }),
    );
    if (respPut.statusCode != 200) {
      await logChomik('$dateNow: setDescription Error StatusCode:${respPut.statusCode}');
    }
  } catch (e) {
    await logChomik('$dateNow: setDescription Error:$e');
  }
}

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum SmsPrediction { ham, spam, loading }

extension ParseToString on SmsPrediction {
  String toShortString() => toString().split(".").last;
}

class SMSMessageWithPrediction {
  late String msg;
  late SmsPrediction prediction;
  late dynamic entities;

  SMSMessageWithPrediction(this.msg, this.prediction, this.entities);
}

Future<SMSMessageWithPrediction> predict(String sms) async {
  // ignore: non_constant_identifier_names

  final API_URL = 'http://127.0.0.1:8000';
  final url = Uri.parse(API_URL);
  final body = jsonEncode({"text": sms});
  final headers = {'Content-Type': 'application/json'};

  final response = await http.post(url, headers: headers, body: body);
  // debugPrint(response.body);
  var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
  // debugPrint(decodedResponse.toString());
  // debugPrint(decodedResponse['itentity']);
  return SMSMessageWithPrediction(sms, parseResults(decodedResponse),
      jsonDecode(decodedResponse['itentity'].replaceAll('\'', '"')));
}

SmsPrediction parseResults(dynamic res) {
  if (res['spam'] == 0) return SmsPrediction.ham;
  return SmsPrediction.spam;
}

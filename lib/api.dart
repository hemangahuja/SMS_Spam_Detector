import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum SmsPrediction { ham, spam }

extension ParseToString on SmsPrediction {
  String toShortString() => toString().split(".").last;
}

class SMSMessageWithPrediction {
  late String msg;
  late SmsPrediction prediction;

  SMSMessageWithPrediction(this.msg, this.prediction);
}

Future<SMSMessageWithPrediction> predict(String sms) async {
  final API_KEY = dotenv.env['API_KEY'];
  final API_URL = dotenv.env['API_URL'];
  var url = Uri.parse(API_URL!);
  var response = await http.post(url, headers: {
    "Authorization": "Bearer $API_KEY"
  }, body: {
    "inputs": sms,
  });
  debugPrint(response.body);
  var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as List;
  debugPrint(decodedResponse.toString());
  return SMSMessageWithPrediction(sms, parseResults(decodedResponse[0]));
}

SmsPrediction parseResults(List<dynamic> res) {
  if (res[0]['label'] == "LABEL_0") return SmsPrediction.ham;
  return SmsPrediction.spam;
}

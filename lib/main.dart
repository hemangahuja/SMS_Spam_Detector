import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import './api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SmsQuery _query = SmsQuery();
  List<SMSMessageWithPrediction> _messages = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SMS Classifier'),
        ),
        body: Container(
          padding: const EdgeInsets.all(10.0),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _messages.length,
            itemBuilder: (BuildContext context, int i) {
              var message = _messages[i];

              return ListTile(
                title: Text(message.prediction.toShortString()),
                subtitle: Text(message.msg),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            var permission = await Permission.sms.status;
            if (permission.isGranted) {
              final messages = await _query.querySms(
                kinds: [SmsQueryKind.inbox, SmsQueryKind.sent],
                // address: '+254712345789',
                count: 2,
              );
              debugPrint('sms inbox messages: ${messages.length}');
              final futures =
                  messages.map((item) => predict(item.body!)).toList();
              final list = await Future.wait(futures);
              setState(() {
                _messages = list;
              });
            } else {
              await Permission.sms.request();
            }
          },
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

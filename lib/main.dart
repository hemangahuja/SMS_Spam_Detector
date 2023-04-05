import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Map<String, int> mp = {};
  int numOfSms = 0;
  bool loading = false;

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
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 50,
                margin: const EdgeInsets.all(10),
                child: TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                  ],
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  onChanged: (nm) {
                    setState(() {
                      numOfSms = int.parse(nm);
                    });
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: mp.values.length,
                  itemBuilder: (BuildContext context, int i) {
                    var message = _messages[i];

                    return ListTile(
                      title: Text(message.prediction.toShortString()),
                      subtitle: RichText(
                        text: TextSpan(
                          children: List.generate(
                              message.entities.length * 2 - 1, (index) {
                            if (index.isEven) {
                              int entityIndex = index ~/ 2;
                              Map<String, dynamic> indexMap =
                                  message.entities[entityIndex];
                              int start = indexMap["start"]!;
                              int end = indexMap["end"]!;
                              return TextSpan(
                                  text: message.msg.substring(
                                    entityIndex == 0
                                        ? 0
                                        : message.entities[entityIndex - 1]
                                            ["end"]!,
                                    start,
                                  ),
                                  style: const TextStyle(color: Colors.black));
                            } else {
                              // Display the underlined text
                              int entityIndex = (index + 1) ~/ 2 - 1;
                              Map<String, dynamic> indexMap =
                                  message.entities[entityIndex];
                              int start = indexMap["start"]!;
                              int end = indexMap["end"]!;
                              return TextSpan(
                                text: message.msg.substring(start, end),
                                style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Colors.black,
                                    fontSize: 20),
                              );
                            }
                          }),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (numOfSms == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Number cannot be zero")));
              return;
            }
            var permission = await Permission.sms.status;
            if (permission.isGranted) {
              final messages = await _query.querySms(kinds: [
                SmsQueryKind.inbox,
              ], count: numOfSms);
              setState(() {
                _messages = messages
                    .map((message) => SMSMessageWithPrediction(
                            message.body!, SmsPrediction.loading, [
                          {"start": 0, "end": message.body!.length - 1}
                        ]))
                    .toList();
                mp.clear();
                for (var i = 0; i < messages.length; i++) {
                  mp.putIfAbsent(messages[i].body!, () => i);
                }
                loading = true;
              });
              debugPrint('sms inbox messages: ${messages.length}');
              final futures =
                  messages.map((item) => predict(item.body!)).toList();
              final stream =
                  Stream<SMSMessageWithPrediction>.fromFutures(futures);
              stream.listen((event) => setState(() {
                    _messages[mp[event.msg]!].prediction = event.prediction;
                    debugPrint(event.entities.toString());
                    _messages[mp[event.msg]!].entities =
                        // jsonDecode(event.entities);
                        event.entities.length > 0
                            ? event.entities
                            : [
                                {"start": 0, "end": event.msg.length - 1}
                              ];
                    loading = false;
                  }));
            } else {
              await Permission.sms.request();
            }
          },
          child: const Icon(Icons.batch_prediction),
        ),
      ),
    );
  }
}

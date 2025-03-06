import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SpeechControlApp extends StatefulWidget {
  @override
  _SpeechControlAppState createState() => _SpeechControlAppState();
}

class _SpeechControlAppState extends State<SpeechControlApp> {
  bool isListening = false;

  Future<void> sendRequest(String endpoint) async {
    final url = Uri.parse('http://127.0.0.1:8000/api/$endpoint/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          isListening = data['running'] ?? false;
        });
        print("Response: ${data['message']}");
      } else {
        print("Error: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Speech Control App")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isListening ? "Listening..." : "Stopped", style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => sendRequest("start"),
              child: Text("Start Recognition"),
            ),
            ElevatedButton(
              onPressed: () => sendRequest("stop"),
              child: Text("Stop Recognition"),
            ),
            ElevatedButton(
              onPressed: () => sendRequest("status"),
              child: Text("Check Status"),
            ),
          ],
        ),
      ),
    );
  }
}

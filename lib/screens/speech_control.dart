import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SpeechControlApp extends StatefulWidget {
  @override
  _SpeechControlAppState createState() => _SpeechControlAppState();
}

class _SpeechControlAppState extends State<SpeechControlApp> with SingleTickerProviderStateMixin {
  bool isListening = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> sendRequest(String endpoint) async {
    // Use different URLs for start and stop
    final url = Uri.parse('http://127.0.0.1:8000/api/${endpoint}/');
    print("🎤 Sending request to: $url");
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("✅ Response data: $data");
        
        setState(() {
          // Update state based on the endpoint rather than response
          isListening = endpoint == "start";
        });
        
        if (isListening) {
          _animationController.repeat(reverse: true);
        } else {
          _animationController.stop();
        }
        print("🎤 Monitoring status: ${isListening ? 'Active' : 'Inactive'}");
      } else {
        print("❌ Error: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 182, 251),
      appBar: AppBar(
        title: Text("Safety Monitor"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Monitor Status",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[900],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isListening ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isListening ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isListening ? Colors.green : Colors.red,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              isListening ? "Active" : "Inactive",
                              style: TextStyle(
                                color: isListening ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => sendRequest(isListening ? "stop" : "start"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isListening ? Colors.red : Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isListening ? Icons.stop : Icons.play_arrow),
                        SizedBox(width: 8),
                        Text(isListening ? "Stop Monitoring" : "Start Monitoring"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Info Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "How it works",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[900],
                    ),
                  ),
                  SizedBox(height: 15),
                  InfoItem(
                    icon: Icons.record_voice_over,
                    text: "Continuously monitors your voice for emergency keywords",
                  ),
                  SizedBox(height: 10),
                  InfoItem(
                    icon: Icons.warning_amber,
                    text: "Detects threat words like 'help', 'emergency', etc.",
                  ),
                  SizedBox(height: 10),
                  InfoItem(
                    icon: Icons.notifications_active,
                    text: "Automatically sends SOS when threats are detected",
                  ),
                ],
              ),
            ),
            if (isListening) ...[
              SizedBox(height: 20),
              // Active Monitoring Indicator
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    FadeTransition(
                      opacity: _animationController,
                      child: Icon(Icons.mic, color: Colors.green),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Actively monitoring for emergency keywords...",
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.purple[700], size: 20),
        ),
        SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:speech_control/screens/userInfo.dart';
import 'screens/map_screen.dart';
import 'screens/speech_control.dart'; // Create this file for Speech Control



void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-Feature App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/map': (context) => MapScreen(),
        '/userInfo': (context) => EmergencyContactScreen(),
        '/speech': (context) => SpeechControlApp(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 182, 251),
      appBar: AppBar(title: Text("Multi-Feature App")),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text("Map"),
              onTap: () => Navigator.pushNamed(context, '/map'),
            ),
            ListTile(
              title: Text("Speech Control"),
              onTap: () => Navigator.pushNamed(context, '/speech'),
            ),
            ListTile(
              title: Text("User Info"),
              onTap: () => Navigator.pushNamed(context, '/userInfo'),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 40.0, left: 40.0, right: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to ResQ',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Your personal safety companion',
              style: TextStyle(
                fontSize: 18,
                color: Colors.purple[800],
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 40),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Features:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[900],
                    ),
                  ),
                  SizedBox(height: 15),
                  FeatureButton(
                    icon: Icons.map,
                    text: 'View Safety Map',
                    onTap: () => Navigator.pushNamed(context, '/map'),
                  ),
                  SizedBox(height: 10),
                  FeatureButton(
                    icon: Icons.mic,
                    text: 'Voice Commands',
                    onTap: () => Navigator.pushNamed(context, '/speech'),
                  ),
                  SizedBox(height: 10),
                  FeatureButton(
                    icon: Icons.contact_phone,
                    text: 'Emergency Contacts',
                    onTap: () => Navigator.pushNamed(context, '/userInfo'),
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

// Add this new widget for consistent button styling
class FeatureButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const FeatureButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purple.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.purple[700]),
              SizedBox(width: 15),
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.purple[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

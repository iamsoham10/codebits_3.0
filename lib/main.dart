import 'package:flutter/material.dart';
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
        '/speech': (context) => SpeechControlApp(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Multi-Feature App")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/map'),
              child: Text("Go to Map"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/speech'),
              child: Text("Go to Speech Control"),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'dart:async';

void main() {
  runApp(const FocusGhostApp());
}

class FocusGhostApp extends StatelessWidget {
  const FocusGhostApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FocusOS Ghost',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(primary: Colors.green),
      ),
      home: const GhostHomeScreen(),
    );
  }
}


class GhostHomeScreen extends StatefulWidget {
  const GhostHomeScreen({super.key});
  @override
  State<GhostHomeScreen> createState() => _GhostHomeScreenState();
}

class _GhostHomeScreenState extends State<GhostHomeScreen> {
  static const platform = MethodChannel('com.ghost.focusos/kiosk');
  bool isEmergencyActive = false;
  int emergencyCredits = 3;
  Timer? _timer;
  int _start = 120;

  @override
  void initState() {
    super.initState();
    _enableKioskMode();
  }

  Future<void> _enableKioskMode() async {
    try { await platform.invokeMethod('startKiosk'); } 
    on PlatformException catch (e) { debugPrint("Error: ${e.message}"); }
  }

  Future<void> _disableKioskMode() async {
    try { 
      await platform.invokeMethod('stopKiosk'); 
      SystemNavigator.pop();
    } on PlatformException catch (e) { debugPrint("Error: ${e.message}"); }
  }

  void _launchApp(String packageName) async {
    await LaunchApp.openApp(androidPackageName: packageName);
  }

  void _startEmergencySession(String pkgName) {
    if (emergencyCredits > 0) {
      setState(() {
        emergencyCredits--;
        isEmergencyActive = true;
        _start = 120;
      });
      _launchApp(pkgName);
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        if (_start == 0) {
          setState(() { timer.cancel(); isEmergencyActive = false; });
          _enableKioskMode();
        } else {
          setState(() { _start--; });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text("FOCUS OS (GHOST)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
            Text("Credits: $emergencyCredits", style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            _buildAppIcon(Icons.terminal, "Termux", () => _launchApp("com.termux"), Colors.green),
            const SizedBox(height: 20),
            _buildAppIcon(Icons.psychology, "AI Chat", () => _launchApp("com.openai.chatgpt"), Colors.blue),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSmallIcon(Icons.call, "Phone", () => _startEmergencySession("com.android.dialer"), Colors.redAccent),
                _buildSmallIcon(Icons.message, "WhatsApp", () => _startEmergencySession("com.whatsapp"), Colors.greenAccent),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(onPressed: _disableKioskMode, child: const Text("EXIT (DEBUG)", style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIcon(IconData icon, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.5))),
        child: Column(children: [Icon(icon, size: 30, color: color), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 10))]),
      ),
    );
  }
  
  Widget _buildSmallIcon(IconData icon, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [Icon(icon, color: color, size: 20), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))]),
    );
  }
}

#!/bin/bash

echo "🚀 Fixing Android V2 Embedding Issue..."

# 1. Folder Setup
mkdir -p lib
mkdir -p android/app/src/main/kotlin/com/example/focus_os_ghost
mkdir -p .github/workflows

# 2. pubspec.yaml
cat <<EOF > pubspec.yaml
name: focus_os_ghost
description: The invisible productivity OS.
version: 1.0.0+1
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  flutter_services_binding: ^0.1.0 
  external_app_launcher: ^3.0.0
  shared_preferences: ^2.2.0
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
flutter:
  uses-material-design: true
EOF

# 3. Android Manifest (FIXED WITH META-DATA)
cat <<EOF > android/app/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.focus_os_ghost">
    <uses-permission android:name="android.permission.REORDER_TASKS"/>
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
    <uses-permission android:name="android.permission.MANAGE_OWN_CALLS"/>
    <application
        android:label="FocusOS"
        android:name="\${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- THE FIX IS HERE -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
            
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.DEFAULT"/> 
            </intent-filter>
        </activity>
        <receiver
            android:name=".SecretCodeReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.provider.Telephony.SECRET_CODE" />
                <data android:scheme="android_secret_code" android:host="2024" />
            </intent-filter>
        </receiver>
    </application>
</manifest>
EOF

# 4. MainActivity.kt
cat <<EOF > android/app/src/main/kotlin/com/example/focus_os_ghost/MainActivity.kt
package com.example.focus_os_ghost

import android.app.ActivityManager
import android.content.Context
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.ghost.focusos/kiosk"
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startKiosk") {
                try {
                    startLockTask()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("KIOSK_ERROR", e.message, null)
                }
            } else if (call.method == "stopKiosk") {
                try {
                    stopLockTask()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("KIOSK_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
EOF

# 5. SecretCodeReceiver.kt
cat <<EOF > android/app/src/main/kotlin/com/example/focus_os_ghost/SecretCodeReceiver.kt
package com.example.focus_os_ghost

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class SecretCodeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "android.provider.Telephony.SECRET_CODE") {
            val i = Intent(context, MainActivity::class.java)
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(i)
        }
    }
}
EOF

# 6. lib/main.dart
cat <<EOF > lib/main.dart
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
    on PlatformException catch (e) { debugPrint("Error: \${e.message}"); }
  }

  Future<void> _disableKioskMode() async {
    try { 
      await platform.invokeMethod('stopKiosk'); 
      SystemNavigator.pop();
    } on PlatformException catch (e) { debugPrint("Error: \${e.message}"); }
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
            Text("Credits: \$emergencyCredits", style: const TextStyle(color: Colors.grey)),
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
EOF

# 7. GitHub Actions Workflow (THE SERVER BUILDER)
cat <<EOF > .github/workflows/build_apk.yml
name: Build Ghost APK
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Java
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'
      - name: Create Base Project & Inject Code
        run: |
          flutter create temp_app --org com.example --project-name focus_os_ghost
          cp pubspec.yaml temp_app/
          cp lib/main.dart temp_app/lib/
          
          # Inject Manifest
          cp android/app/src/main/AndroidManifest.xml temp_app/android/app/src/main/
          
          # Inject Kotlin Files
          mkdir -p temp_app/android/app/src/main/kotlin/com/example/focus_os_ghost
          cp android/app/src/main/kotlin/com/example/focus_os_ghost/*.kt temp_app/android/app/src/main/kotlin/com/example/focus_os_ghost/
          
          cd temp_app
          flutter pub get
          flutter build apk --release --no-tree-shake-icons
          mv build/app/outputs/flutter-apk/app-release.apk ../ghost-mode.apk
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: focus-os-ghost-apk
          path: ghost-mode.apk
EOF

echo "✅ Fix Ready! Save and Run."


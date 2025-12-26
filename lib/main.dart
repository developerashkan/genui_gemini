import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:genui_gemini/dynamic_genui_app.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MaterialApp(home: DynamicGenUIApp()));
}




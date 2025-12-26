import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiApi {
  GeminiApi._();
  static final apiKey = dotenv.env['API_KEY']!;
  static final model = dotenv.env['MODEL']!;
}
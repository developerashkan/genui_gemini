# genui_gemini

Dynamic Generative UI with Flutter & Google Gemini AI  
Enable your Flutter apps with AI-driven interfaces — the AI decides which UI components to render based on user queries.

---

## Demo

[▶ Watch demo video](https://github.com/user-attachments/assets/38f4f012-d9bd-4ad6-b6b8-8e733650747c)

---

## Features

- **AI-driven UI generation:** Gemini AI selects the best UI components for each user query.
- **Natural language conversation:** Interact with your app using plain language.
- **Multiple component support:** Includes WeatherCard, InfoCard, ListCard, and more.
- **Dynamic surfaces:** UI updates in real-time based on AI decisions.
- **Secure API key management:** Supports `.env` files or `--dart-define` to keep API keys safe.

---

## Installation

Add the required dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  genui: ^0.6.0
  google_generative_ai: ^0.4.7
  json_schema_builder: ^0.1.3
  flutter_dotenv: ^6.0.0

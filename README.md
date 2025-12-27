# genui_gemini

Dynamic Generative UI with Flutter & Google Gemini AI  
Enable your Flutter apps with AI-driven interfaces — the AI decides which UI components to render based on user queries.

---

## Demo

<video width="600" controls>
  <source src="assets/demo/genui.webm" type="video/webm">
  Your browser does not support the video tag.
</video>

---

## Features

- AI-driven UI generation: Gemini AI selects the best UI components for each user query.
- Natural language conversation: Interact with your app in plain language.
- Multiple component support: WeatherCard, InfoCard, ListCard, and more.
- Dynamic surfaces: UI updates in real time based on AI decisions.
- Secure API key management: Supports `.env` or `--dart-define` to keep keys safe.

---

## Installation

Add the required dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  cupertino_icons: ^1.0.8
  genui: ^0.6.0
  google_generative_ai: ^0.4.7
  json_schema_builder: ^0.1.3
  flutter_dotenv: ^6.0.0

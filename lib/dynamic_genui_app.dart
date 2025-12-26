import 'package:flutter/material.dart';
import 'package:genui/genui.dart' as genUI;
import 'package:genui_gemini/api.dart';
import 'package:genui_gemini/dynamic_gemini_content_generator.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as dsb;

class DynamicGenUIApp extends StatefulWidget {
  const DynamicGenUIApp({super.key});

  @override
  State<DynamicGenUIApp> createState() => _DynamicGenUIAppState();
}

class _DynamicGenUIAppState extends State<DynamicGenUIApp> {
  late final genUI.GenUiConversation _conversation;
  late final genUI.A2uiMessageProcessor _messageProcessor;
  final List<String> _activeSurfaceIds = [];
  final List<String> _textResponses = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // MULTIPLE UI COMPONENTS

    // 1. Weather Card
    final weatherCard = genUI.CatalogItem(
      name: 'WeatherCard',
      dataSchema: dsb.S.object(
        properties: {
          'city': dsb.S.string(description: 'City name'),
          'temp': dsb.S.string(description: 'Temperature with unit'),
          'condition': dsb.S.string(description: 'Weather condition like Sunny, Rainy, Cloudy'),
          'humidity': dsb.S.string(description: 'Humidity percentage'),
        },
        required: ['city', 'temp'],
      ),
      widgetBuilder: (ctx) => _buildWeatherCard(ctx),
    );

    // 2. Info Card - For general information
    final infoCard = genUI.CatalogItem(
      name: 'InfoCard',
      dataSchema: dsb.S.object(
        properties: {
          'title': dsb.S.string(description: 'Card title'),
          'content': dsb.S.string(description: 'Main content text'),
          'icon': dsb.S.string(description: 'Icon name: info, warning, success, error, question'),
        },
        required: ['title', 'content'],
      ),
      widgetBuilder: (ctx) => _buildInfoCard(ctx),
    );

    // 3. List Card - For showing lists
    final listCard = genUI.CatalogItem(
      name: 'ListCard',
      dataSchema: dsb.S.object(
        properties: {
          'title': dsb.S.string(description: 'List title'),
          'items': dsb.S.string(description: 'Comma-separated list items'),
        },
        required: ['title', 'items'],
      ),
      widgetBuilder: (ctx) => _buildListCard(ctx),
    );

    // 4. Forecast Card - For weather forecasts
    final forecastCard = genUI.CatalogItem(
      name: 'ForecastCard',
      dataSchema: dsb.S.object(
        properties: {
          'city': dsb.S.string(description: 'City name'),
          'date': dsb.S.string(description: 'Date of forecast'),
          'condition': dsb.S.string(description: 'Expected weather condition'),
          'highTemp': dsb.S.string(description: 'High temperature'),
          'lowTemp': dsb.S.string(description: 'Low temperature'),
          'rainChance': dsb.S.string(description: 'Chance of rain percentage'),
        },
        required: ['city', 'date', 'condition'],
      ),
      widgetBuilder: (ctx) => _buildForecastCard(ctx),
    );

    // 5. Text Response Card - For plain text answers
    final textCard = genUI.CatalogItem(
      name: 'TextCard',
      dataSchema: dsb.S.object(
        properties: {
          'text': dsb.S.string(description: 'The text response'),
        },
        required: ['text'],
      ),
      widgetBuilder: (ctx) => _buildTextCard(ctx),
    );

    final customCatalog = genUI.Catalog(
      [weatherCard, infoCard, listCard, forecastCard, textCard],
      catalogId: 'dynamic-catalog',
    );

    _messageProcessor = genUI.A2uiMessageProcessor(
      catalogs: [
        genUI.CoreCatalogItems.asCatalog(),
        customCatalog,
      ],
    );

    final contentGenerator = DynamicGeminiContentGenerator(
      apiKey: GeminiApi.apiKey,
      catalog: customCatalog,
    );

    _conversation = genUI.GenUiConversation(
      a2uiMessageProcessor: _messageProcessor,
      contentGenerator: contentGenerator,
      onSurfaceAdded: (update) {
        debugPrint('✅ Surface added: ${update.surfaceId}');
        setState(() => _activeSurfaceIds.add(update.surfaceId));
      },
      onSurfaceDeleted: (update) {
        debugPrint('🗑️ Surface deleted: ${update.surfaceId}');
        setState(() => _activeSurfaceIds.remove(update.surfaceId));
      },
      onTextResponse: (text) {
        debugPrint('✅ Text Response: $text');
        setState(() => _textResponses.add(text));
      },
      onError: (error) {
        debugPrint('❌ Error: ${error.error}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${error.error}'), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  // WIDGET BUILDERS

  Widget _buildWeatherCard(genUI.CatalogItemContext ctx) {
    final data = ctx.data as Map<String, Object?>?;
    final city = ctx.dataContext.subscribeToString(data?['city'] as Map<String, Object?>?);
    final temp = ctx.dataContext.subscribeToString(data?['temp'] as Map<String, Object?>?);
    final condition = ctx.dataContext.subscribeToString(data?['condition'] as Map<String, Object?>?);
    final humidity = ctx.dataContext.subscribeToString(data?['humidity'] as Map<String, Object?>?);

    return ValueListenableBuilder<String?>(
      valueListenable: city,
      builder: (_, cityVal, __) => ValueListenableBuilder<String?>(
        valueListenable: temp,
        builder: (_, tempVal, __) => ValueListenableBuilder<String?>(
          valueListenable: condition,
          builder: (_, condVal, __) => ValueListenableBuilder<String?>(
            valueListenable: humidity,
            builder: (_, humVal, __) {
              return Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getWeatherColors(condVal ?? 'sunny'),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                                Text(cityVal ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(condVal ?? 'Unknown', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                          ],
                        ),
                        Text(tempVal ?? '--', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w300)),
                      ],
                    ),
                    if (humVal != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.water_drop, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text('Humidity: $humVal', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Color> _getWeatherColors(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('rain')) return [Colors.blueGrey, Colors.grey];
    if (cond.contains('cloud')) return [Colors.grey, Colors.blueGrey];
    if (cond.contains('snow')) return [Colors.lightBlue.shade100, Colors.white];
    if (cond.contains('storm')) return [Colors.deepPurple, Colors.grey.shade800];
    return [Colors.blue, Colors.lightBlue];
  }

  Widget _buildInfoCard(genUI.CatalogItemContext ctx) {
    final data = ctx.data as Map<String, Object?>?;
    final title = ctx.dataContext.subscribeToString(data?['title'] as Map<String, Object?>?);
    final content = ctx.dataContext.subscribeToString(data?['content'] as Map<String, Object?>?);
    final icon = ctx.dataContext.subscribeToString(data?['icon'] as Map<String, Object?>?);

    return ValueListenableBuilder<String?>(
      valueListenable: title,
      builder: (_, titleVal, __) => ValueListenableBuilder<String?>(
        valueListenable: content,
        builder: (_, contentVal, __) => ValueListenableBuilder<String?>(
          valueListenable: icon,
          builder: (_, iconVal, __) {
            return Card(
              margin: const EdgeInsets.all(12),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_getInfoIcon(iconVal ?? 'info'), color: _getInfoColor(iconVal ?? 'info'), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(titleVal ?? 'Information', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(contentVal ?? '', style: const TextStyle(fontSize: 15, height: 1.5)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getInfoIcon(String icon) {
    switch (icon.toLowerCase()) {
      case 'warning': return Icons.warning_amber_rounded;
      case 'success': return Icons.check_circle;
      case 'error': return Icons.error;
      case 'question': return Icons.help;
      default: return Icons.info;
    }
  }

  Color _getInfoColor(String icon) {
    switch (icon.toLowerCase()) {
      case 'warning': return Colors.orange;
      case 'success': return Colors.green;
      case 'error': return Colors.red;
      case 'question': return Colors.purple;
      default: return Colors.blue;
    }
  }

  Widget _buildListCard(genUI.CatalogItemContext ctx) {
    final data = ctx.data as Map<String, Object?>?;
    final title = ctx.dataContext.subscribeToString(data?['title'] as Map<String, Object?>?);
    final items = ctx.dataContext.subscribeToString(data?['items'] as Map<String, Object?>?);

    return ValueListenableBuilder<String?>(
      valueListenable: title,
      builder: (_, titleVal, __) => ValueListenableBuilder<String?>(
        valueListenable: items,
        builder: (_, itemsVal, __) {
          final itemList = (itemsVal ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          return Card(
            margin: const EdgeInsets.all(12),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titleVal ?? 'List', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...itemList.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item, style: const TextStyle(fontSize: 15))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForecastCard(genUI.CatalogItemContext ctx) {
    final data = ctx.data as Map<String, Object?>?;
    final city = ctx.dataContext.subscribeToString(data?['city'] as Map<String, Object?>?);
    final date = ctx.dataContext.subscribeToString(data?['date'] as Map<String, Object?>?);
    final condition = ctx.dataContext.subscribeToString(data?['condition'] as Map<String, Object?>?);
    final highTemp = ctx.dataContext.subscribeToString(data?['highTemp'] as Map<String, Object?>?);
    final lowTemp = ctx.dataContext.subscribeToString(data?['lowTemp'] as Map<String, Object?>?);
    final rainChance = ctx.dataContext.subscribeToString(data?['rainChance'] as Map<String, Object?>?);

    return ValueListenableBuilder<String?>(
      valueListenable: city,
      builder: (_, cityVal, __) => ValueListenableBuilder<String?>(
        valueListenable: date,
        builder: (_, dateVal, __) => ValueListenableBuilder<String?>(
          valueListenable: condition,
          builder: (_, condVal, __) => ValueListenableBuilder<String?>(
            valueListenable: highTemp,
            builder: (_, highVal, __) => ValueListenableBuilder<String?>(
              valueListenable: lowTemp,
              builder: (_, lowVal, __) => ValueListenableBuilder<String?>(
                valueListenable: rainChance,
                builder: (_, rainVal, __) {
                  return Card(
                    margin: const EdgeInsets.all(12),
                    elevation: 4,
                    color: Colors.indigo.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('📍 ${cityVal ?? "Unknown"}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(dateVal ?? '', style: TextStyle(color: Colors.grey.shade700)),
                            ],
                          ),
                          const Divider(),
                          Row(
                            children: [
                              Icon(_getWeatherIcon(condVal ?? ''), size: 40, color: Colors.indigo),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(condVal ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                  if (highVal != null || lowVal != null)
                                    Text('High: ${highVal ?? "--"} / Low: ${lowVal ?? "--"}', style: TextStyle(color: Colors.grey.shade600)),
                                ],
                              ),
                            ],
                          ),
                          if (rainVal != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.umbrella, size: 20, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text('Rain chance: $rainVal', style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('rain')) return Icons.water_drop;
    if (cond.contains('cloud')) return Icons.cloud;
    if (cond.contains('snow')) return Icons.ac_unit;
    if (cond.contains('storm') || cond.contains('thunder')) return Icons.flash_on;
    if (cond.contains('fog') || cond.contains('mist')) return Icons.blur_on;
    return Icons.wb_sunny;
  }

  Widget _buildTextCard(genUI.CatalogItemContext ctx) {
    final data = ctx.data as Map<String, Object?>?;
    final text = ctx.dataContext.subscribeToString(data?['text'] as Map<String, Object?>?);

    return ValueListenableBuilder<String?>(
      valueListenable: text,
      builder: (_, textVal, __) {
        return Card(
          margin: const EdgeInsets.all(12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(textVal ?? '', style: const TextStyle(fontSize: 15, height: 1.6)),
          ),
        );
      },
    );
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    debugPrint('📤 Sending: $text');
    _conversation.sendRequest(genUI.UserMessage.text(text));
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GenUI Gemini Assistant'),
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _activeSurfaceIds.isEmpty && _textResponses.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ask me anything!', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Weather, forecasts, general questions...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _activeSurfaceIds.length,
                itemBuilder: (context, index) {
                  return genUI.GenUiSurface(
                    host: _conversation.host,
                    surfaceId: _activeSurfaceIds[index],
                  );
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Ask anything...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.indigo,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _conversation.dispose();
    super.dispose();
  }
}
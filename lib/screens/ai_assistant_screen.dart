import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/vehicle_provider.dart';
import '../data/vehicle_spec_database.dart';

// IMPORTANT: This is a placeholder. Never hardcode API keys in a production app.
// We now use flutter_dotenv to read from .env file.
String get _kGeminiApiKey =>
    dotenv.env['GEMINI_API_KEY'] ?? 'YOUR_GEMINI_API_KEY_HERE';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late GenerativeModel _model;
  ChatSession? _chatSession;

  @override
  void initState() {
    super.initState();
    _initAI();
  }

  void _initAI() {
    // Initialize the model
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _kGeminiApiKey,
    );

    // Add an initial greeting
    _messages.add(ChatMessage(
      text:
          "Hello! I am your Moto Vitals AI Mechanic. How can I help you with your motorcycle today?",
      isUser: false,
    ));
  }

  Future<void> _startChatSession(BuildContext context) async {
    final vehicle = context.read<VehicleProvider>().currentVehicle;
    String systemInstruction =
        "You are an expert motorcycle mechanic. You provide concise, accurate troubleshooting advice.";

    if (vehicle != null) {
      systemInstruction +=
          " The user is currently riding a ${vehicle.make} ${vehicle.modelName} with ${vehicle.odo.toStringAsFixed(0)} km on the odometer.";
      if (vehicle.specModelId != null) {
        final spec = VehicleSpecDatabase.findById(vehicle.specModelId!);
        if (spec != null) {
          systemInstruction +=
              " Important specs: Engine Oil Capacity is ${spec.oil.volumeLiters}L, Coolant Capacity is ${spec.coolant?.volumeLiters ?? 'N/A'}L, Spark Plug Gap is ${spec.sparkPlug.gap}. Use this exact information if they ask about oil, coolant, or spark plugs.";
        }
      }
    }

    // In a real app with Gemini 1.5 Pro, we could use systemInstructions.
    // For now, we simulate it by starting the history with a hidden context prompt if needed,
    // or we just prepend it to the first user query implicitly.
    _chatSession = _model.startChat();
    // We will inject the system instruction into the first prompt to ensure it works even on older SDKs
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_kGeminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please add your Gemini API Key in lib/screens/ai_assistant_screen.dart to use this feature.')),
      );
      return;
    }

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      if (_chatSession == null) {
        await _startChatSession(context);
      }

      // Inject system context if it's the first message
      final vehicle = context.read<VehicleProvider>().currentVehicle;
      String contextPrefix = "";
      if (_messages.where((m) => m.isUser).length == 1 && vehicle != null) {
        contextPrefix =
            "[System Context: User rides a ${vehicle.make} ${vehicle.modelName} with ${vehicle.odo.toStringAsFixed(0)}km] ";
      }

      final response =
          await _chatSession!.sendMessage(Content.text(contextPrefix + text));

      setState(() {
        _messages.add(ChatMessage(
          text: response.text ?? "I'm sorry, I couldn't generate a response.",
          isUser: false,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages
            .add(ChatMessage(text: 'Error: ${e.toString()}', isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A24),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.smart_toy_rounded, color: Colors.deepPurpleAccent),
            const SizedBox(width: 8),
            Text('AI Mechanic',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurpleAccent : const Color(0xFF1A1A24),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          border: isUser
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Text(
          msg.text,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Ask about maintenance, sounds, or issues...',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: Colors.deepPurpleAccent,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

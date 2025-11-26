import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';

class DraggableChatbot extends StatefulWidget {
  const DraggableChatbot({Key? key}) : super(key: key);

  @override
  _DraggableChatbotState createState() => _DraggableChatbotState();
}

class _DraggableChatbotState extends State<DraggableChatbot> {
  static Offset? savedPosition;
  late Offset position;

  @override
  void initState() {
    super.initState();
    print('DraggableChatbot initState called');
    print('savedPosition: $savedPosition');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final screenSize = MediaQuery.of(context).size;
      final buttonSize = 60.0;
      
      print('Screen size in callback: $screenSize');
      
      final newPosition = savedPosition ?? Offset(
        screenSize.width - buttonSize - 5,
        screenSize.height - buttonSize - 85,
      );
      
      if (position != newPosition) {
        setState(() {
          position = newPosition;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('DraggableChatbot build called');
    
    final screenSize = MediaQuery.of(context).size;
    final buttonSize = 60.0;
    
    if (!_isInitialized) {
      position = savedPosition ?? Offset(
        screenSize.width - buttonSize - 5,
        screenSize.height - buttonSize - 85,
      );
      _isInitialized = true;
    }
    
    print('Displaying at position: $position');

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable(
        feedback: _buildChatbotButton(isDragging: true),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            double newX = details.offset.dx;
            double newY = details.offset.dy;

            final screenSize = MediaQuery.of(context).size;
            final buttonSize = 40.0;

            newX = newX.clamp(0.0, screenSize.width - buttonSize);
            newY = newY.clamp(0.0, screenSize.height - buttonSize - 80);

            position = Offset(newX, newY);
            savedPosition = position;
            
            print('Position saved: $savedPosition');
          });
        },
        child: _buildChatbotButton(isDragging: false),
      ),
    );
  }

  bool _isInitialized = false;

  Widget _buildChatbotButton({required bool isDragging}) {
    return GestureDetector(
      onTap: isDragging
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatbotPage()),
              );
            },
      child: Opacity(
        opacity: 0.6,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.4),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/icon/robot.png',
              width: 50,
              height: 50,
            ),
          ),
        ),
      ),
    );
  }
}

// Chatbot Page with API Integration
class ChatbotPage extends StatefulWidget {
  const ChatbotPage({Key? key}) : super(key: key);

  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  
  List<ChatMessage> messages = [
    ChatMessage(
      text: "Hello! I'm your AI assistant. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _getAIResponseFromAPI(String userMessage) async {
    const String apiUrl = 'https://keugh3ttkl.execute-api.us-east-1.amazonaws.com/dev/ask';
    
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'prompt': userMessage,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Adjust this based on your actual API response structure
        // Common patterns: responseData['response'], responseData['answer'], responseData['data']
        return responseData['response'] ?? responseData['answer'] ?? responseData.toString();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      print('Error calling API: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  String _getFallbackResponse(String userMessage) {
    String lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('stock') || lowerMessage.contains('inventory')) {
      return "I can help you with stock management! You can view your current inventory levels, check products running low, and get restock recommendations in the Dashboard.";
    } else if (lowerMessage.contains('forecast') ||
        lowerMessage.contains('predict')) {
      return "Our AI forecast analyzes your sales history to predict future demand. Upload your sales data in the Sales Data section to generate accurate forecasts.";
    } else if (lowerMessage.contains('product')) {
      return "To add a new product, go to the 'Add Product' tab and fill in the details including product name, SKU, pricing, and stock quantity.";
    } else if (lowerMessage.contains('help')) {
      return "I can assist you with:\n• Stock management\n• Sales forecasting\n• Product information\n• Dashboard insights\n\nWhat would you like to know more about?";
    } else if (lowerMessage.contains('risk')) {
      return "Risk levels are calculated based on days until stockout:\n• Low Risk: >7 days\n• Medium Risk: 4-7 days\n• High Risk: <4 days\n\nCheck the Dashboard for detailed risk analysis.";
    } else {
      return "I understand you're asking about: \"$userMessage\". Could you provide more details so I can assist you better?";
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    
    setState(() {
      messages.add(
        ChatMessage(
          text: userMessage,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _messageController.clear();

    // Scroll to bottom after user message
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Get AI response from API
    final aiResponse = await _getAIResponseFromAPI(userMessage);

    setState(() {
      messages.add(
        ChatMessage(
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = false;
    });

    // Scroll to bottom after AI response
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        elevation: 4,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blue[600],
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset(
                  'assets/icon/robot.png',
                  width: 28,
                  height: 28,
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && _isLoading) {
                  return _buildLoadingIndicator();
                }
                return _buildMessageBubble(messages[index]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Thinking...',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: message.isUser
                ? Radius.circular(4)
                : Radius.circular(16),
            bottomLeft: message.isUser
                ? Radius.circular(16)
                : Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use Markdown widget for AI responses, regular Text for user messages
            message.isUser
                ? Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  )
                : MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                      strong: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                      em: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[800],
                      ),
                      listBullet: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                      ),
                      code: TextStyle(
                        backgroundColor: Colors.grey[300],
                        color: Colors.grey[900],
                        fontFamily: 'monospace',
                      ),
                      h1: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                      h2: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                      h3: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                  ),
            SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: message.isUser ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: _isLoading ? 'Waiting for response...' : 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                filled: true,
                fillColor: _isLoading ? Colors.grey[100] : Colors.grey[50],
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _isLoading ? null : _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _isLoading ? Colors.grey[400] : Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isLoading ? null : _sendMessage,
              icon: Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
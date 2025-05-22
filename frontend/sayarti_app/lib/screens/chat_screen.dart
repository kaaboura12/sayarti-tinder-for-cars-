import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final int otherUserId;
  final String otherUserName;
  final int carId;
  final String carTitle;

  const ChatScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
    required this.carId,
    required this.carTitle,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message>? _messages;
  bool _isLoading = false;
  String? _errorMessage;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
      });
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.token;

      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication required';
          _isLoading = false;
        });
        return;
      }

      final messages = await _messageService.getConversation(
        widget.otherUserId,
        widget.carId,
        token,
      );

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        
        // Scroll to the bottom after loading messages
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load messages: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.token;

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')),
        );
        return;
      }

      final message = await _messageService.sendMessage(
        receiverId: widget.otherUserId,
        carId: widget.carId,
        message: messageText,
        token: token,
      );

      if (message != null && mounted) {
        setState(() {
          _messages ??= [];
          _messages!.add(message);
        });

        // Scroll to the bottom after sending a message
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  String _formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat.jm().format(dateTime); // e.g., 2:15 PM
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUserName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.carTitle,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[300] : Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: isDarkMode ? AppTheme.darkSurfaceColor : null,
        elevation: 0,
        flexibleSpace: isDarkMode
            ? null
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red[800],
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _loadMessages,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : _messages == null || _messages!.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: isDarkMode
                                      ? AppTheme.darkHeadingMedium.copyWith(fontSize: 18)
                                      : TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start the conversation',
                                  style: isDarkMode
                                      ? AppTheme.darkBodyMedium
                                      : TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            itemCount: _messages!.length,
                            itemBuilder: (context, index) {
                              final message = _messages![index];
                              final isCurrentUser = message.senderId == _currentUserId;
                              return _buildMessageBubble(message, isCurrentUser, isDarkMode);
                            },
                          ),
          ),
          
          // Message input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Message text field
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Show the other user's avatar only for their messages
          if (!isCurrentUser)
            CircleAvatar(
              backgroundColor: AppTheme.accentColor.withOpacity(0.8),
              radius: 16,
              child: Text(
                message.senderFirstname?.isNotEmpty == true
                    ? message.senderFirstname![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          const SizedBox(width: 8),
          
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppTheme.primaryColor
                    : (isDarkMode ? Colors.grey[800] : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isCurrentUser ? const Radius.circular(18) : const Radius.circular(5),
                  bottomRight: isCurrentUser ? const Radius.circular(5) : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Message text
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isCurrentUser
                          ? Colors.white
                          : (isDarkMode ? Colors.white : Colors.black87),
                      fontSize: 15,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Message time
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: isCurrentUser
                          ? Colors.white.withOpacity(0.8)
                          : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Show the current user's avatar only for their messages
          if (isCurrentUser)
            CircleAvatar(
              backgroundColor: AppTheme.accentColor.withOpacity(0.8),
              radius: 16,
              child: Text(
                message.senderFirstname?.isNotEmpty == true
                    ? message.senderFirstname![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 
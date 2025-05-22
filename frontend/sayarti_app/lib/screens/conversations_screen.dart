import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/conversation_model.dart';
import '../services/message_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final MessageService _messageService = MessageService();
  List<Conversation>? _conversations;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
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

      final conversations = await _messageService.getConversations(token);
      
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load conversations: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return 'No time';
    }
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        // Today, show time
        return DateFormat.jm().format(dateTime);
      } else if (difference.inDays == 1) {
        // Yesterday
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        // Less than a week, show day name
        return DateFormat.E().format(dateTime);
      } else {
        // More than a week, show date
        return DateFormat.yMd().format(dateTime);
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
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
      body: _isLoading
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
                        onPressed: _loadConversations,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _conversations == null || _conversations!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum,
                            size: 64,
                            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No conversations yet',
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
                            'Start messaging a seller',
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
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _conversations!.length,
                        itemBuilder: (context, index) {
                          final conversation = _conversations![index];
                          return _buildConversationTile(conversation, isDarkMode);
                        },
                      ),
                    ),
    );
  }

  Widget _buildConversationTile(Conversation conversation, bool isDarkMode) {
    return Card(
      color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                otherUserId: conversation.otherUserId,
                otherUserName: '${conversation.otherUserFirstname} ${conversation.otherUserName}',
                carId: conversation.carId,
                carTitle: conversation.carTitle,
              ),
            ),
          ).then((_) => _loadConversations());
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Car image or placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: conversation.carPhoto != null
                    ? Image.network(
                        conversation.carPhoto!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                            child: Icon(
                              Icons.car_repair,
                              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                        child: Icon(
                          Icons.car_repair,
                          color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Message info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contact name
                    Text(
                      '${conversation.otherUserFirstname} ${conversation.otherUserName}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppTheme.darkTextColor : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Car name
                    Text(
                      conversation.carTitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? AppTheme.darkTextLightColor : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Last message
                    Text(
                      conversation.lastMessage ?? 'No messages yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? AppTheme.darkTextLightColor : Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDateTime(conversation.lastMessageTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? AppTheme.darkTextLightColor : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
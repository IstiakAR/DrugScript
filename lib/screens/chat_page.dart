import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> messages = [];
  bool isLoading = true;
  String? currentUserId;
  static const String _cacheKey = 'cached_messages';
  static const String _userCacheKey = 'cached_user_names';

  Map<String, Map<String, dynamic>> userCache = {};

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final user = _authService.currentUser;
    currentUserId = user?.uid;
    await _loadCachedMessages();
    await _loadMessages();
  }

  Future<void> _loadCachedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final cachedUserData = prefs.getString(_userCacheKey);
      if (cachedData != null) {
        final cachedMessages = jsonDecode(cachedData) as List;
        setState(() {
          messages = cachedMessages;
          isLoading = false;
        });
        if (cachedUserData != null) {
          userCache = Map<String, Map<String, dynamic>>.from(
            (jsonDecode(cachedUserData) as Map).map(
              (k, v) => MapEntry(k, Map<String, dynamic>.from(v)),
            ),
          );
        }
        await _preloadUserNames(cachedMessages); // <-- preload names
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading cached messages: $e');
    }
  }

  Future<void> _cacheMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(messages));
      await prefs.setString(_userCacheKey, jsonEncode(userCache));
    } catch (e) {
      print('Error caching messages: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final fetchedMessages = await _chatService.getMessages();
      setState(() {
        messages = fetchedMessages;
        isLoading = false;
      });
      await _preloadUserNames(fetchedMessages); // <-- preload names
      await _cacheMessages();
      await _checkForMentions(fetchedMessages); // Check for mentions after loading messages
      _scrollToBottom();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Add a method to check for mentions
  Future<void> _checkForMentions(List<dynamic> messages) async {
    if (currentUserId == null) return;
    
    try {
      // Get current user name
      final currentUserInfo = await _getUserInfo(currentUserId!);
      final currentUserName = currentUserInfo['name'] as String;
      
      // Check if user is mentioned in any message
      bool isMentioned = false;
      for (final message in messages) {
        final senderId = message['sender_id'];
        if (senderId != currentUserId) { // Don't count self-mentions
          final content = message['content'] as String? ?? '';
          if (content.contains('@$currentUserName')) {
            isMentioned = true;
            break;
          }
        }
      }
      
      // Store mention status in SharedPreferences
      if (isMentioned) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_unread_mention', true);
      }
    } catch (e) {
      print('Error checking mentions: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || currentUserId == null) return;

    final messageContent = _messageController.text.trim();
    _messageController.clear();

    // Create temporary message for immediate display with current local time
    final tempMessage = {
      'content': messageContent,
      'sender_id': currentUserId,
      'timestamp': DateTime.now().toIso8601String(), // Keep as local time for temp message
      'temp_id': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    // Add message immediately to UI
    setState(() {
      messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      final success = await _chatService.sendMessage(currentUserId!, messageContent);
      if (success) {
        // Find and update the temporary message instead of removing it
        final tempIndex = messages.indexWhere((msg) => msg['temp_id'] == tempMessage['temp_id']);
        if (tempIndex != -1) {
          // Try to get the latest message from server
          final latestMessage = await _chatService.getLatestMessage();
          if (latestMessage != null && latestMessage['content'] == messageContent) {
            setState(() {
              messages[tempIndex] = latestMessage;
            });
          } else {
            // If can't get latest, just remove temp_id to make it permanent
            setState(() {
              messages[tempIndex].remove('temp_id');
            });
          }
          await _cacheMessages();
        }
      } else {
        // Remove temp message on failure
        setState(() {
          messages.removeWhere((msg) => msg['temp_id'] == tempMessage['temp_id']);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send message')),
          );
        }
      }
    } catch (e) {
      // Remove temp message on error
      setState(() {
        messages.removeWhere((msg) => msg['temp_id'] == tempMessage['temp_id']);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    // Check cache first
    if (userCache.containsKey(userId)) {
      return userCache[userId]!;
    }

    // For current user, get info from AuthService
    if (userId == currentUserId) {
      final user = _authService.currentUser;
      final userInfo = {
        'name': user?.displayName ?? 'You',
      };
      userCache[userId] = userInfo;
      return userInfo;
    }

    // For other users, fetch from API
    try {
      final userDetails = await _chatService.getUserDetails(userId);
      final userInfo = {
        'name': userDetails?['name'] ?? 'Unknown User',
      };
      userCache[userId] = userInfo;
      return userInfo;
    } catch (e) {
      final fallbackInfo = {
        'name': 'Unknown User',
      };
      userCache[userId] = fallbackInfo;
      return fallbackInfo;
    }
  }

  Future<void> _preloadUserNames(List<dynamic> messages) async {
    final uniqueUserIds = messages
        .map((msg) => msg['sender_id'])
        .where((id) => id != null)
        .toSet();

    for (final userId in uniqueUserIds) {
      if (!userCache.containsKey(userId)) {
        await _getUserInfo(userId);
      }
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Community Chat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 100, 149, 237),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message['sender_id'] == currentUserId;
                          final isTemp = message.containsKey('temp_id');
                          
                          return _buildMessageBubble(
                            message['content'] ?? '',
                            isMe,
                            message['sender_id'] ?? 'Unknown',
                            message['timestamp'] ?? '',
                            isTemp,
                          );
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isMe, String senderId, String timestamp, bool isTemp) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserInfo(senderId),
      builder: (context, snapshot) {
        final userInfo = snapshot.data ?? {'name': 'Loading...'};
        final userName = userInfo['name'] as String;

        return GestureDetector(
          onDoubleTap: () {
            // Only allow mentioning others, not yourself
            if (!isMe && userName != 'Loading...') {
              final mention = '@$userName ';
              final currentText = _messageController.text;
              // Avoid duplicate mentions
              if (!currentText.contains(mention)) {
                setState(() {
                  _messageController.text = '$currentText$mention';
                  _messageController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _messageController.text.length),
                  );
                });
              }
            }
          },
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isMe 
                    ? (isTemp ? const Color.fromARGB(200, 100, 149, 237) : const Color.fromARGB(255, 100, 149, 237))
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe)
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          content,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isMe && isTemp) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (timestamp.isNotEmpty && !isTemp)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey[500],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
        );
      },
    );
  }

String _formatTimestamp(String timestamp) {
  try {
    DateTime dateTime;

    if (timestamp.contains('+') || timestamp.endsWith('Z')) {
      // Server timestamp with timezone info
      dateTime = DateTime.parse(timestamp).toLocal();
    } else {
      // Might be stored in UTC without zone, force parse as UTC then convert
      dateTime = DateTime.parse(timestamp).toUtc().add(const Duration(hours: 6));
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative || difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  } catch (e) {
    return 'Unknown time';
  }
}


  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 100, 149, 237),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

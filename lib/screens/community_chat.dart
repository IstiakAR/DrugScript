import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class CommunityChatPage extends StatefulWidget {
  const CommunityChatPage({Key? key}) : super(key: key);

  @override
  State<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  List<dynamic> chatChannels = [];
  int selectedChannelIndex = 0;
  List<dynamic> messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoadingChannels = true;
  bool _isLoadingMessages = false;
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = _authService.currentUser?.uid;
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    setState(() => _isLoadingChannels = true);
    final channels = await _chatService.getChannels();
    // Always ensure General is present and at the top, using backend id
    final general = channels.firstWhere(
      (c) => (c['name']?.toLowerCase() ?? '') == 'general',
      orElse: () => null,
    );
    List<dynamic> updatedChannels = List.from(channels);
    if (general != null) {
      updatedChannels.removeWhere((c) => (c['name']?.toLowerCase() ?? '') == 'general');
      updatedChannels.insert(0, general);
    }
    setState(() {
      chatChannels = updatedChannels;
      _isLoadingChannels = false;
      selectedChannelIndex = -1; // No chat selected initially
      messages = []; // Clear messages when no chat is selected
    });
    // Do not load messages initially
  }

  Future<void> _loadMessages() async {
    if (chatChannels.isEmpty || selectedChannelIndex < 0) return;
    setState(() => _isLoadingMessages = true);
    final channelId = chatChannels[selectedChannelIndex]['id'] ?? chatChannels[selectedChannelIndex]['name'];
    final msgs = await _chatService.getMessages(channelId);
    setState(() {
      messages = msgs;
      _isLoadingMessages = false;
    });
    // Scroll to bottom after loading messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendMessage() async {
    if (chatChannels.isEmpty || selectedChannelIndex < 0) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final user = _authService.currentUser;
    if (user == null) return;

    var channel = chatChannels[selectedChannelIndex];
    String? channelId = channel['id'];

    // For General, ensure we have a valid backend id
    if (channel['name'].toString().toLowerCase() == 'general') {
      if (channelId == null || channelId == 'general') {
        // Try to reload channels to get the backend id
        await _loadChannels();
        channel = chatChannels.firstWhere(
          (c) => (c['name']?.toLowerCase() ?? '') == 'general',
          orElse: () => null,
        );
        channelId = channel != null ? channel['id'] : null;
        if (channelId == null || channelId == 'general') {
          // Still no valid id, abort
          print('General channel does not have a valid backend id.');
          return;
        }
      }
    }

    final success = await _chatService.sendMessage(channelId!, user.uid, text);
    if (success) {
      _messageController.clear();
      await _loadMessages();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _showCreatePrivateChatDialog() async {
    String privateName = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Private Chat'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Chat Name',
            hintText: 'Enter chat name',
          ),
          onChanged: (value) {
            privateName = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (privateName.trim().isNotEmpty && userId != null) {
                final created = await _chatService.createChannel(privateName.trim(), userId!);
                if (created != null) {
                  Navigator.of(context).pop();
                  await _loadChannels();
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChannel(int index) async {
    if (chatChannels.isEmpty || userId == null) return;
    final channel = chatChannels[index];
    final String channelName = channel['name'];
    final String channelId = channel['id'];
    // Prevent deletion of General channel or channels not owned by user
    if (channelName.toLowerCase() == 'general' || channel['owner_id'] != userId) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete "$channelName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _chatService.deleteChannel(channelId, userId!);
              Navigator.of(context).pop();
              await _loadChannels();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentChannel = (selectedChannelIndex >= 0 && chatChannels.isNotEmpty)
        ? chatChannels[selectedChannelIndex]
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/homePage'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Create Private Chat",
            onPressed: _showCreatePrivateChatDialog,
          ),
          // Only show delete button if not General and user is owner
          if (currentChannel != null &&
              currentChannel['name'].toString().toLowerCase() != 'general' &&
              currentChannel['owner_id'] == userId)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: "Delete this chat",
              onPressed: () => _deleteChannel(selectedChannelIndex),
            ),
        ],
      ),
      body: _isLoadingChannels
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Chat Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (int i = 0; i < chatChannels.length; i++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(
                                    label: Text(
                                      chatChannels[i]['name'],
                                      style: TextStyle(
                                        color: selectedChannelIndex == i
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    selected: selectedChannelIndex == i,
                                    selectedColor: Colors.blue[700],
                                    backgroundColor: Colors.grey[200],
                                    onSelected: (selected) async {
                                      setState(() {
                                        selectedChannelIndex = i;
                                      });
                                      await _loadMessages();
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Messages
                Expanded(
                  child: selectedChannelIndex < 0
                      ? const Center(child: Text('Select a chat to view messages.'))
                      : _isLoadingMessages
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, idx) {
                                final msg = messages[idx];
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(msg['content'] ?? ''),
                                  ),
                                );
                              },
                            ),
                ),
                // Message Input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          enabled: selectedChannelIndex >= 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                        onPressed: (selectedChannelIndex < 0 ||
                                _isLoadingMessages ||
                                _messageController.text.trim().isEmpty)
                            ? null
                            : _sendMessage,
                      ),
                    ],
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

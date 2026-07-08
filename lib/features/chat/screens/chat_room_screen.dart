import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firestore_service.dart';
import '../../../providers/auth_provider.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String targetName;
  final String campaignId;
  final String targetId;
  final String? umkmId;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.targetName,
    required this.campaignId,
    required this.targetId,
    this.umkmId,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messageController = TextEditingController();
  String? _detectedUmkmId;

  @override
  void initState() {
    super.initState();
    _detectedUmkmId = widget.umkmId;
    if (_detectedUmkmId == null) {
      _loadChatInfo();
    }
  }

  void _loadChatInfo() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
      if (doc.exists && mounted) {
        setState(() {
          _detectedUmkmId = doc.data()?['umkmId'];
        });
      }
    } catch (e) {
      // ignore
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    
    final user = await ref.read(currentUserProvider.future);
    if (user != null) {
      try {
        await FirestoreService().sendMessage(
          widget.chatId,
          user.uid,
          widget.targetId,
          text,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengirim pesan: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.targetName),
            Text(
              'ID Campaign: ${widget.campaignId}',
              style: const TextStyle(fontSize: 10, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User error'));
          
          final isAdmin = user.role == 'admin';

          return Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirestoreService().getMessagesStream(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final messages = snapshot.data?.docs ?? [];

                    return ListView.builder(
                      reverse: true, // List dimulai dari bawah
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final data = messages[index].data() as Map<String, dynamic>;
                        final senderId = data['senderId'];
                        
                        final bool isMe;
                        final String senderLabel;
                        final Color bubbleColor;
                        final Color textColor;
                        final Alignment alignment;

                        if (isAdmin) {
                          final isUmkm = senderId == _detectedUmkmId;
                          alignment = isUmkm ? Alignment.centerRight : Alignment.centerLeft;
                          bubbleColor = isUmkm 
                              ? Theme.of(context).primaryColor.withOpacity(0.9) 
                              : Colors.purple.shade100;
                          textColor = isUmkm ? Colors.white : Colors.purple.shade900;
                          senderLabel = isUmkm ? 'UMKM' : 'Influencer';
                          isMe = isUmkm;
                        } else {
                          isMe = senderId == user.uid;
                          alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
                          bubbleColor = isMe ? Theme.of(context).primaryColor : Colors.grey.shade200;
                          textColor = isMe ? Colors.white : Colors.black87;
                          senderLabel = '';
                        }
                        
                        return Align(
                          alignment: alignment,
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isAdmin)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2, left: 4, right: 4),
                                  child: Text(
                                    senderLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isMe ? Theme.of(context).primaryColor : Colors.purple.shade700,
                                    ),
                                  ),
                                ),
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: bubbleColor,
                                  borderRadius: BorderRadius.circular(16).copyWith(
                                    bottomRight: isMe ? const Radius.circular(0) : null,
                                    bottomLeft: !isMe ? const Radius.circular(0) : null,
                                  ),
                                ),
                                child: Text(
                                  data['message'],
                                  style: TextStyle(color: textColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Input bar / Admin monitor banner
              isAdmin
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border(top: BorderSide(color: Colors.red.shade200)),
                      ),
                      child: SafeArea(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.security, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Mode Pemantauan Admin (Hanya Baca)',
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.attach_file),
                              onPressed: () {},
                            ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Tulis pesan...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              color: Theme.of(context).primaryColor,
                              onPressed: _sendMessage,
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

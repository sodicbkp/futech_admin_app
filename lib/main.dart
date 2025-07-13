import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';
import 'config.dart'; // Updated config with async methods
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(FutechAdminApp());
}

class FutechAdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Futech Admin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<String> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final url = await AppConfig.supportUsersUrl;
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      List<dynamic> data = json.decode(res.body);
      setState(() {
        users = data.map((e) => e.toString()).toList();
      });
    }
  }

  void _openBaseUrlDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUrl = await AppConfig.getBaseUrl();
    TextEditingController controller = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Change Base URL'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: "Base URL"),
        ),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("Save"),
            onPressed: () async {
              await AppConfig.setBaseUrl(controller.text.trim());
              Navigator.pop(context);
              fetchUsers(); // Refresh list with new URL
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Futech Support Users"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _openBaseUrlDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchUsers,
        child: ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            String userId = users[index];
            return ListTile(
              leading: CircleAvatar(child: Text(userId.substring(0, 2))),
              title: Text(userId),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(userId: userId),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String userId;
  ChatScreen({required this.userId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> messages = [];
  TextEditingController controller = TextEditingController();
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    final url = await AppConfig.supportMessagesUrl(widget.userId);
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      List<dynamic> data = json.decode(res.body);
      setState(() {
        messages = data.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> sendMessage(String text) async {
    final url = await AppConfig.adminReplyUrl;
    final res = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"user_id": widget.userId, "message": text}),
    );
    if (res.statusCode == 200) {
      controller.clear();
      fetchMessages();
    }
  }

  Widget buildMessage(Map<String, dynamic> msg) {
    bool isAdmin = msg['from'] == 'admin';
    String text = msg['text'];
    Widget content;

    if (text.startsWith("/static/voices/")) {
      content = IconButton(
        icon: Icon(Icons.play_arrow),
        onPressed: () async {
          final base = await AppConfig.getBaseUrl();
          await player.setUrl("$base$text");
          player.play();
        },
      );
    } else if (text.startsWith("/static/attachments/")) {
      final base = AppConfig.getBaseUrl();
      if (text.endsWith(".jpg") || text.endsWith(".png") || text.endsWith(".jpeg") || text.endsWith(".gif")) {
        content = FutureBuilder<String>(
          future: base,
          builder: (_, snapshot) {
            if (!snapshot.hasData) return SizedBox();
            return Image.network("${snapshot.data}$text", height: 150);
          },
        );
      } else {
        content = FutureBuilder<String>(
          future: base,
          builder: (_, snapshot) {
            if (!snapshot.hasData) return SizedBox();
            return TextButton(
              child: Text("📎 Download Attachment"),
              onPressed: () async {
                final url = "${snapshot.data}$text";
                if (await canLaunch(url)) {
                  await launch(url);
                }
              },
            );
          },
        );
      }
    } else {
      content = Text(text);
    }

    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: isAdmin ? Colors.green[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat: ${widget.userId}")),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchMessages,
              child: ListView(
                children: messages.map(buildMessage).toList(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Type your reply...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    String text = controller.text.trim();
                    if (text.isNotEmpty) {
                      sendMessage(text);
                    }
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

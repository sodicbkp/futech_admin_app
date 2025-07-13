import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
  }

  void _loadBaseUrl() async {
    final url = await AppConfig.getBaseUrl();
    controller.text = url;
  }

  void _saveBaseUrl() async {
    await AppConfig.setBaseUrl(controller.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Base URL saved"),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: "Base URL"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveBaseUrl,
              child: Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}

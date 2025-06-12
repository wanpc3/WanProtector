import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';

class ViewDeletedEntry extends StatefulWidget {
  final int oldId;
  final VoidCallback? onRestored;

  ViewDeletedEntry({
    required this.oldId,
    this.onRestored
  });

  @override
  _ViewDeletedEntryState createState() => _ViewDeletedEntryState();
}

class _ViewDeletedEntryState extends State<ViewDeletedEntry> {
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _obscurePassword = true;
  final Databasehelper _dbHelper = Databasehelper();
  late Future<Map<String, dynamic>?> _entryFuture;

  @override
  void initState() {
    super.initState();
    _entryFuture = _loadDeletedEntry();
  }

  Future<Map<String, dynamic>?> _loadDeletedEntry() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'deleted_entry',
      where: 'deleted_id = ?',
      whereArgs: [widget.oldId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      final entry = result[0];
      _titleController.text = entry['title'] as String? ?? '';
      _usernameController.text = entry['username'] as String? ?? '';
      _passwordController.text = entry['password'] as String? ?? '';
      _urlController.text = entry['url'] as String? ?? '';
      _notesController.text = entry['notes'] as String? ?? '';
      return entry;
    }
    return null;
  }

  void _restoreEntry() async {
    await _dbHelper.restoreEntry(widget.oldId);
    widget.onRestored?.call();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Deleted Entry'),
        actions: [
          IconButton(
            icon: Icon(Icons.restore_from_trash),
            onPressed: _restoreEntry,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _entryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text("No entry found"));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: "Title"),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _usernameController,
                        enabled: false,
                        decoration: InputDecoration(labelText: "Username"),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _usernameController.text),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Username copied to clipboard')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        enabled: false,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(labelText: "Password"),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _passwordController.text),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Password copied to clipboard')),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(labelText: "Url"),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: "Notes"),
                  enabled: false,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

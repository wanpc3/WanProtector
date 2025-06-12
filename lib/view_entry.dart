import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';
import 'edit_entry.dart';

class ViewEntry extends StatefulWidget {
  final int entryId;
  final VoidCallback? onEntryUpdated;

  ViewEntry({
    required this.entryId,
    this.onEntryUpdated
  });

  @override
  _ViewEntryState createState() => _ViewEntryState();
}

class _ViewEntryState extends State<ViewEntry> {
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
    _entryFuture = _loadData();
  }

  Future<Map<String, dynamic>?> _loadData() async {
    return await _dbHelper.getEntryById(widget.entryId);
  }

  void _updateControllers(Map<String, dynamic> entry) {
    _titleController.text = entry['title'];
    _usernameController.text = entry['username'];
    _passwordController.text = entry['password'] ?? '';
    _urlController.text = entry['url'] ?? '';
    _notesController.text = entry['notes'] ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _deleteEntry(int id) async {
    await _dbHelper.softDeleteEntry(id);
    widget.onEntryUpdated?.call();
    Navigator.pop(context, true);
  }

  void _navigateToEditEntry(Map<String, dynamic> entry) async {
    final result = await Navigator.push(
      context,
        MaterialPageRoute(
          builder: (context) => EditEntry(
            entry: Map.from(entry)
          ),
      )
    );

    if (result == true) {
      widget.onEntryUpdated?.call();
      setState(() {
        _entryFuture = _loadData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _entryFuture,
          builder: (context, snapshot) {
            return Text('View Entry');
          },
        ),
        actions: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _entryFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'Delete') {
                    _deleteEntry(snapshot.data!['id']);
                  } else if (value == 'Edit') {
                    _navigateToEditEntry(snapshot.data!);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'Delete',
                    child: Text("Delete Entry"),
                  ),
                  const PopupMenuItem(
                    value: 'Edit',
                    child: Text("Edit Entry"),
                  ),
                ],
              );
            },
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _entryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error loading entry'));
          }
          
          if (!snapshot.hasData) {
            return Center(child: Text('Entry not found'));
          }
          
          _updateControllers(snapshot.data!);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [

                //Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: "Title"),
                  enabled: false,
                ),

                const SizedBox(height: 16),

                //Username
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

                //Password
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

                //Url
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(labelText: "Url"),
                  enabled: false,
                ),

                const SizedBox(height: 16),

                //Notes
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
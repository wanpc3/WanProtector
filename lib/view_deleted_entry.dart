import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'entries_state.dart';
import 'deleted_state.dart';
import 'vault.dart';

class ViewDeletedEntry extends StatefulWidget {
  final int oldId;

  ViewDeletedEntry({
    required this.oldId,
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
  final Vault _dbHelper = Vault();
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

  //To restore deleted entry
  void _restoreEntry() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _dbHelper.restoreEntry(widget.oldId);

      //Refresh the deleted entry so it updates.
      final stateDeletedManager = context.read<DeletedState>();
      await stateDeletedManager.refreshDeletedEntries();

      //Refresh the entry as well.
      final stateManager = context.read<EntriesState>();
      await stateManager.refreshEntries();

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("The entry has been restored"),
            backgroundColor: Colors.green[400],
            duration: Duration(seconds: 2),
          )
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"))
        );
      }
    }
  }

  //To delete entry permanently
  void _deleteEntryPermanently() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator()
      ),
    );

    try {
      await _dbHelper.deleteEntryPermanently(widget.oldId);

      final stateDeletedManager = context.read<DeletedState>();
      await stateDeletedManager.refreshDeletedEntries();

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('The entry has been permanently deleted'),
            backgroundColor: Colors.red[400],
              duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch(e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"))
        );
      }
    }
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

  //Date Formatter
  String formatDateTime(String dateTimeString) {
    final dt = DateTime.parse(dateTimeString).toLocal();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _entryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Loading...');
            }
            if (snapshot.hasData && snapshot.data != null) {
              final title = snapshot.data!['title'];
              return Text('$title');
            }
            return Text('Entry #${widget.oldId}');
          },
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [

          //Restore Icon
          IconButton(
            icon: Icon(Icons.restore_from_trash),
            onPressed: _restoreEntry,
          ),

          //Delete Permanently option
          FutureBuilder<Map<String, dynamic>?>(
            future: _entryFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'Delete Permanently') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Permanently Delete?"),
                        content: Text('This action cannot be undone. Are you sure?'),
                        actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false), 
                              child: Text('Cancel')
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true), 
                              child: Text('Delete')
                            ),
                          ],
                        ),
                      );

                    if (confirm == true) {
                      _deleteEntryPermanently();
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'Delete Permanently',
                    child: Text("Delete Permanently"),
                  ),
                ],
              );
            },
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

          final deletedEntry = snapshot.data!;
          final createdAt = formatDateTime(deletedEntry['created_at']);
          final lastUpdated = formatDateTime(deletedEntry['last_updated']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
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

                //Time created and last updated
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text("Created at: $createdAt"),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("Last updated at: $lastUpdated"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

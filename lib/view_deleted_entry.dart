import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/deleted_entry.dart';
import 'entries_state.dart';
import 'deleted_state.dart';
import 'vault.dart';
import 'normalize_url.dart';

class ViewDeletedEntry extends StatefulWidget {
  final DeletedEntry deletedEntry;

  ViewDeletedEntry({
    Key? key,
    required this.deletedEntry,
  }): super(key: key);

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
  
  late DeletedEntry _currentDeletedEntry;

  @override
  void initState() {
    super.initState();
    _currentDeletedEntry = widget.deletedEntry;
    _updateControllers(widget.deletedEntry);
  }

  void _updateControllers(DeletedEntry deletedEntry) {
    _titleController.text = deletedEntry.title;
    _usernameController.text = deletedEntry.username;
    _passwordController.text = deletedEntry.password!;
    _urlController.text = deletedEntry.url!;
    _notesController.text = deletedEntry.notes!;
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
      await _dbHelper.restoreEntry(_currentDeletedEntry.deletedId!);

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
            content: Text('"${_currentDeletedEntry.title}" Restored'),
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
      await _dbHelper.deleteEntryPermanently(_currentDeletedEntry.deletedId!);

      final stateDeletedManager = context.read<DeletedState>();
      await stateDeletedManager.refreshDeletedEntries();

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_currentDeletedEntry.title}" permanently deleted'),
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
        backgroundColor: const Color(0xFF000000),
        foregroundColor: Colors.white,
        title: Text(_currentDeletedEntry.title),
        actions: [

          //Restore Icon
          IconButton(
            icon: Icon(Icons.restore_from_trash),
            onPressed: _restoreEntry,
          ),
          
          PopupMenuButton<String>(
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
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            //Title
            Hero(
              tag: 'title-${_currentDeletedEntry.title}',
              child: Material(
                type: MaterialType.transparency,
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: "Title"),
                  enabled: false,
                ),
              ),
            ),

            const SizedBox(height: 16),

            //Username
            Hero(
              tag: 'username-${_currentDeletedEntry.username}',
              child: Material(
                type: MaterialType.transparency,
                child: Row(
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
              ),
            ),

            const SizedBox(height: 16),

            //Password
            Hero(
              tag: 'password-${_currentDeletedEntry.password}',
              child: Material(
                type: MaterialType.transparency,
                child: Row(
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
              ),
            ),

            const SizedBox(height: 16),

            //Url
            GestureDetector(
              onTap: () async {
                
                final rawUrl = _currentDeletedEntry.url ?? '';
                final formattedUrl = NormalizeUrl.urlFormatter(rawUrl);

                if (formattedUrl.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: const Text('The URL field is empty.')),
                  );
                  return;
                }

                //Ask permission to leave the app to access clicked link
                final confirmed = await showDialog(
                  context: context, 
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Open Link in Browser?"),
                      content: const Text("You are about to leave this app to open the link in your browser. Do you want to proceed?"),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        TextButton(
                          child: const Text('Open'),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    );
                  }
                );

                if (confirmed == true && await canLaunchUrl(Uri.parse(formattedUrl))) {
                  await launchUrl(Uri.parse(formattedUrl), mode: LaunchMode.externalApplication);
                }
              },
              child: Hero(
                tag: 'url-${_currentDeletedEntry.url}',
                child: Material(
                  type: MaterialType.transparency,
                  child: TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(labelText: "Url"),
                    enabled: false,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            //Notes
            Hero(
              tag: 'notes-${_currentDeletedEntry.notes}',
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  height: 150,
                  child: TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(labelText: "Notes"),
                    minLines: 4,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    enabled: false,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            //Created and Updated
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text("Created at: ${formatDateTime(_currentDeletedEntry.createdAt)}"),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text("Last updated at: ${formatDateTime(_currentDeletedEntry.lastUpdated)}"),
            ),
          ],
        ),
      ),
    );
  }
}

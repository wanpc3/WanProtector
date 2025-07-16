import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/deleted_entry.dart';
import 'entries_state.dart';
import 'deleted_state.dart';
import 'alerts.dart';
import 'vault.dart';
import 'normalize_url.dart';
import 'copy_to_clipboard.dart';

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
    _passwordController.text = deletedEntry.password ?? '';
    _urlController.text = deletedEntry.url ?? '';
    _notesController.text = deletedEntry.notes ?? '';
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

      if (context.mounted) Navigator.of(context).pop();

      //Snackbar message
      final alertsEnabled = context.read<AlertsProvider>().showAlerts;
      if (alertsEnabled && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
        ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                '${_currentDeletedEntry.title} Restored',
                style: TextStyle(color: Colors.white),
              ),
            ),
            backgroundColor: Colors.green[400],
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          )
        );
      }

      if (context.mounted) Navigator.pop(context, true);

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

      if (context.mounted) Navigator.of(context).pop();

      //Snackbar message
      final alertsEnabled = context.read<AlertsProvider>().showAlerts;
      if (alertsEnabled && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
        ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                '${_currentDeletedEntry.title} permanently deleted',
                style: TextStyle(color: Colors.white),
              ),
            ),
            backgroundColor: Colors.red[400],
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      
      if (context.mounted) Navigator.pop(context, true);

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
        backgroundColor: const Color(0xFF424242),
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
                    title: const Text('Permanently Delete?'),
                    content: const Text('This action cannot be undone. Are you sure?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true), 
                        child: const Text('Delete')
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
            
            const SizedBox(height: 16),

            //Title
            Hero(
              tag: 'title-${_currentDeletedEntry.title}',
              child: Material(
                type: MaterialType.transparency,
                child: TextFormField(
                  controller: _titleController,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    labelText: "Title",
                    labelStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                    ),
                    disabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                      ),
                    ),
                  ),
                  enabled: false,
                  maxLines: 1,
                  minLines: 1,
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
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        decoration: InputDecoration(
                          labelText: "Username",
                          labelStyle: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                          ),
                          disabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                            ),
                          ),
                        ),
                        maxLines: 1,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy),
                      onPressed: () {
                        final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                        if (alertsEnabled && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
                          copyToClipboardWithFeedback(context, '👤', 'Username', _usernameController.text);
                        } else {
                          Clipboard.setData(ClipboardData(text: _usernameController.text));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            //Password
            Hero(
              tag: 'password-${_currentDeletedEntry.password ?? 'empty'}',
              child: Material(
                type: MaterialType.transparency,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        enabled: false,
                        obscureText: _obscurePassword,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                          ),
                          disabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                            ),
                          ),
                        ),
                        minLines: 1,
                        maxLines: _obscurePassword ? 1 : null,
                      ),
                    ),

                    const SizedBox(width: 4),

                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                        if (alertsEnabled && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
                          copyToClipboardWithFeedback(context, '🔑', 'Password', _passwordController.text);
                        } else {
                          Clipboard.setData(ClipboardData(text: _passwordController.text));
                        }
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
                final alertsEnabled = context.read<AlertsProvider>().showAlerts;

                if (alertsEnabled && formattedUrl.isEmpty && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
                  ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Center(
                        child: const Text('🔗 The URL field is empty'),
                      ),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 40.0,
                        vertical: 20.0,
                      ),
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                if (!alertsEnabled && formattedUrl.isEmpty) return;

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
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Hero(
                  tag: 'url-${_currentDeletedEntry.url ?? 'empty'}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _urlController,
                            decoration: InputDecoration(
                              labelText: "Url",
                              labelStyle: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                              ),
                              disabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                                ),
                              ),
                            ),
                            enabled: false,
                            maxLines: 1,
                            style: TextStyle(color: Colors.blue[800]),
                          ),
                        ),

                        const SizedBox(width: 4),

                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                            if (alertsEnabled && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
                              copyToClipboardWithFeedback(context, '🔗', 'URL', _urlController.text);
                            } else {
                              Clipboard.setData(ClipboardData(text: _urlController.text));
                            }
                          }
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            //Notes
            Hero(
              tag: 'notes-${_currentDeletedEntry.notes ?? 'empty'}',
              child: Material(
                type: MaterialType.transparency,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 100),
                  child: TextFormField(
                    controller: _notesController,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      labelText: "Notes",
                      labelStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                      ),
                      disabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                        ),
                      ),
                      alignLabelWithHint: true,
                    ),
                    minLines: 3,
                    maxLines: null,
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

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

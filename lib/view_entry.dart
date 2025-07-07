import 'alerts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/entry.dart';
import 'deleted_state.dart';
import 'entries_state.dart';
import 'vault.dart';
import 'edit_entry.dart';
import 'normalize_url.dart';

class ViewEntry extends StatefulWidget {
  final Entry entry;

  const ViewEntry({
    Key? key,
    required this.entry,
  }): super(key: key);

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
  final Vault _dbHelper = Vault();

  late Entry _currentEntry;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
    _updateControllers(widget.entry);
  }

  void _updateControllers(Entry entry) {
    _titleController.text = entry.title;
    _usernameController.text = entry.username;
    _passwordController.text = entry.password!;
    _urlController.text = entry.url!;
    _notesController.text = entry.notes!;
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

  //Entry removal
  void _removeEntry(int id) async {
    showDialog(
      context: context,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    try {
      await _dbHelper.softDeleteEntry(id);

      final stateManager = context.read<EntriesState>();
      await stateManager.refreshEntries();

      final deletedStateManager = context.read<DeletedState>();
      await deletedStateManager.refreshDeletedEntries();

      if (context.mounted) Navigator.of(context).pop();

      //Snackbar message
      final alertsEnabled = context.read<AlertsProvider>().showAlerts;
      if (alertsEnabled && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_currentEntry.title} moved to Deleted Entries',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red[400],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      if (context.mounted) Navigator.pop(context, true);

    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  void _navigateToEditEntry(Entry entry) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => EditEntry(
          entry: _currentEntry,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.fastLinearToSlowEaseIn;
        
        return SlideTransition(
          position: animation.drive(
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve))
          ),
          child: ScaleTransition(
            scale: animation.drive(
              Tween(begin: 0.95, end: 1.0).chain(
                CurveTween(curve: Curves.fastOutSlowIn)
              ),
            ),
            child: FadeTransition(
              opacity: animation.drive(
                CurveTween(curve: const Interval(0.3, 1.0))
              ),
              child: child,
            ),
          ),
        );
      },
        transitionDuration: Duration(milliseconds: 350),
        reverseTransitionDuration: Duration(milliseconds: 350),
      ),
    );

    if (result == true) {
      final updated = await _dbHelper.getEntryById(_currentEntry.id!);
      if (updated != null) {
        setState(() {
          _currentEntry = updated;
          _updateControllers(_currentEntry);
        });
      }
    }
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
        title: Text(_currentEntry.title),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'Delete') {
                _removeEntry(widget.entry.id!);
              } else if (value == 'Edit') {
                _navigateToEditEntry(_currentEntry);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Delete', child: Text("Delete Entry")),
              PopupMenuItem(value: 'Edit', child: Text("Edit Entry")),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            //Title
            Hero(
              tag: 'title-${_currentEntry.title}',
              child: Material(
                type: MaterialType.transparency,
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: "Title",
                    filled: true,
                    fillColor: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabled: false,
                  maxLines: null,
                  minLines: 1,
                ),
              ),
            ),

            const SizedBox(height: 16),

            //Username
            Hero(
              tag: 'username-${_currentEntry.username}',
              child: Material(
                type: MaterialType.transparency,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _usernameController,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: "Username",
                          filled: true,
                          fillColor: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        maxLines: null,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _usernameController.text),
                        );

                        //Snackbar message
                        final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                        if (alertsEnabled && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Username copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
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
              tag: 'password-${_currentEntry.password}',
              child: Material(
                type: MaterialType.transparency,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        enabled: false,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          filled: true,
                          fillColor: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        maxLines: null,
                      ),
                    ),

                    const SizedBox(width: 4),

                    IconButton(
                      icon: Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _passwordController.text),
                        );

                        //Snackbar message
                        final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                        if (alertsEnabled && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Password copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
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
                
                final rawUrl = _currentEntry.url ?? '';
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
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Hero(
                  tag: 'url-${_currentEntry.url}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: "Url",
                        suffixIcon: Icon(Icons.open_in_new, size: 18),
                      ),
                      enabled: false,
                      maxLines: null,
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            //Notes
            Hero(
              tag: 'notes-${_currentEntry.notes}',
              child: Material(
                type: MaterialType.transparency,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 100),
                  child: TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: "Notes",
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
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
              child: Text("Created at: ${formatDateTime(_currentEntry.createdAt)}"),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text("Last updated at: ${formatDateTime(_currentEntry.lastUpdated)}"),
            ),
          ],
        ),
      ),
    );
  }
}
import 'alerts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'models/entry.dart';
import 'deleted_state.dart';
import 'entries_state.dart';
import 'vault.dart';
import 'edit_entry.dart';
import 'normalize_url.dart';
import 'copy_to_clipboard.dart';

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
    _passwordController.text = entry.password ?? '';
    _urlController.text = entry.url ?? '';
    _notesController.text = entry.notes ?? '';
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

  //Delete Entry
  void _deleteEntry(int id) async {
    showDialog(
      context: context,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    try {
      
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Entry?'),
          content: Text('${_currentEntry.title} will be moved to Deleted Entries page'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Proceed'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _dbHelper.softDeleteEntry(id);

        final stateManager = context.read<EntriesState>();
        await stateManager.refreshEntries();

        final deletedStateManager = context.read<DeletedState>();
        await deletedStateManager.refreshDeletedEntries();

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
                  '${_currentEntry.title} moved to Deleted Entries',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
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

  //Share Entry
  Future<String> generateShareableEntryText(Entry entry) async {
    final decryptedUsername = entry.username;
    final decryptedPassword = entry.password ?? '-';
    final decryptedNotes = entry.notes ?? '-';
    final url = entry.url ?? '-';

    return '''
${entry.title}

Title: ${entry.title}
Username: $decryptedUsername
Password: $decryptedPassword
URL: $url
Notes: $decryptedNotes

''';
  }

  void _shareEntry(String title) async {
    final content = await generateShareableEntryText(_currentEntry);
    await Share.share(content, subject: '$title');
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
              
              /*
              if (value == 'Edit') {
                _navigateToEditEntry(_currentEntry);
              }
              */

              if (value == 'Delete') {
                _deleteEntry(widget.entry.id!);
              } else if (value == 'Edit') {
                _navigateToEditEntry(_currentEntry);
              } else if (value == 'Share') {
                _shareEntry(widget.entry.title);
              }
              
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Delete', child: Text("Delete")),
              PopupMenuItem(value: 'Edit', child: Text("Edit")),
              PopupMenuItem(value: 'Share', child: Text("Share"),),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [

            const SizedBox(height: 16),

            //Title
            Hero(
              tag: 'title-${_currentEntry.title}',
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
              tag: 'username-${_currentEntry.username}',
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
                      icon: const Icon(Icons.copy),
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
              tag: 'password-${_currentEntry.password ?? 'empty'}',
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
                      icon: Icon(Icons.copy),
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
                
                final rawUrl = _currentEntry.url ?? '';
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
                  tag: 'url-${_currentEntry.url ?? 'empty'}',
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
              tag: 'notes-${_currentEntry.notes ?? 'empty'}',
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
              child: Text("Created at: ${formatDateTime(_currentEntry.createdAt)}"),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text("Last updated at: ${formatDateTime(_currentEntry.lastUpdated)}"),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
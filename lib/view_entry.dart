import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'deleted_entries_state_manager.dart';
import 'entries_state.dart';
import 'vault.dart';
import 'edit_entry.dart';

class ViewEntry extends StatefulWidget {
  final int entryId;
  final VoidCallback? onEntryUpdated;
  final Function(int)? onEntryDeleted;

  ViewEntry({
    Key? key,
    required this.entryId,
    required this.onEntryUpdated,
    this.onEntryDeleted,
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
  late Future<Map<String, dynamic>?> _entryFuture;

  @override
  void initState() {
    super.initState();
    _entryFuture = _loadDataAndSetControllers();
  }

  Future<Map<String, dynamic>?> _loadDataAndSetControllers() async {
    final entry = await _dbHelper.getEntryById(widget.entryId);
    if (entry != null) {
      _updateControllers(entry);
    }
    return entry;
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

  //Entry removal
  void _removeEntry(int id) async {
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      // 1. Perform soft delete in database
      await _dbHelper.softDeleteEntry(id);
      
      // 2. Update both states
      final entriesState = context.read<EntriesState>();
      final deletedEntriesState = context.read<DeletedEntriesStateManager>();
      
      entriesState.removeEntry(id);
      await deletedEntriesState.refreshDeletedEntries();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Entry moved to deleted items"))
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"))
        );
      }
    }
  }

  void _navigateToEditEntry(Map<String, dynamic> entry) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => EditEntry(
          entry: Map.from(entry),
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
      widget.onEntryUpdated?.call();
      setState(() {
        _entryFuture = _loadDataAndSetControllers();
      });
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
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
          return Text('Entry #${widget.entryId}');
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
                    _removeEntry(snapshot.data!['id']);
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
          
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Entry not found'));
          }

          final entry = snapshot.data!;
          final createdAt = formatDateTime(entry['created_at']);
          final lastUpdated = formatDateTime(entry['last_updated']);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [

                // Title (with Hero)
                Hero(
                  tag: 'title-${widget.entryId}',
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

                // Username (with Hero)
                Hero(
                  tag: 'username-${widget.entryId}',
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

                // Password (with Hero)
                Hero(
                  tag: 'password-${widget.entryId}',
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

                // Url (with Hero)
                Hero(
                  tag: 'url-${widget.entryId}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(labelText: "Url"),
                      enabled: false,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Notes (with Hero)
                Hero(
                  tag: 'notes-${widget.entryId}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(labelText: "Notes"),
                      enabled: false,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Created and Updated 
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
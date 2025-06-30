import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'entries_state.dart';
import 'models/entry.dart';
import 'vault.dart';
import 'normalize_url.dart';
import 'alerts.dart';

class EditEntry extends StatefulWidget {
  final Entry? entry;

  const EditEntry({
    Key? key,
    this.entry,
  }): super(key: key);

  @override
  _EditEntryState createState() => _EditEntryState();
}

class _EditEntryState extends State<EditEntry> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _obscurePassword = true;
  final Vault _dbHelper = Vault();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _usernameController.text = widget.entry!.username;
      _passwordController.text = widget.entry!.password!;
      _urlController.text = widget.entry!.url!;
      _notesController.text = widget.entry!.notes!;
    }

    _titleController.addListener(_checkForChanges);
    _usernameController.addListener(_checkForChanges);
    _passwordController.addListener(_checkForChanges);
    _urlController.addListener(_checkForChanges);
    _notesController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final newState = _titleController.text != widget.entry!.title ||
        _usernameController.text != widget.entry!.username ||
        _passwordController.text != (widget.entry!.password) ||
        _urlController.text != (widget.entry!.url) ||
        _notesController.text != (widget.entry!.notes);

    if (newState != _hasChanges) {
      setState(() {
        _hasChanges = newState;
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_checkForChanges);
    _usernameController.removeListener(_checkForChanges);
    _passwordController.removeListener(_checkForChanges);
    _urlController.removeListener(_checkForChanges);
    _notesController.removeListener(_checkForChanges);
    
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  void _saveEntry() async {
    if (_formKey.currentState!.validate()) {

      await Future.delayed(Duration(microseconds: 300));

      final id = widget.entry!.id;
      final newTitle = _titleController.text.trim();
      final newUsername = _usernameController.text.trim();
      final newPassword = _passwordController.text.trim();
      final newUrl = _urlController.text.trim();
      final newNotes = _notesController.text.trim();

      //Auto-correct URL
      String formattedUrl = NormalizeUrl.urlFormatter(newUrl);
      

      await _dbHelper.updateEntry(
        id!, 
        newTitle, 
        newUsername, 
        newPassword, 
        formattedUrl, 
        newNotes
      );

      //Snackbar message
      final alertsEnabled = context.read<AlertsProvider>().showAlerts;
      if (alertsEnabled && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Entry Updated'),
            backgroundColor: Colors.green[400],
            duration: const Duration(seconds: 3),
          ),
        );
      }

      //Refresh the entry so it updates.
      final stateManager = context.read<EntriesState>();
      await stateManager.refreshEntries();

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text("Edit Entry"),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () async {
              final canPop = await _onWillPop();
              if (canPop) {
                Navigator.pop(context);
              }
            },
          ),
          backgroundColor: const Color(0xFF000000),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveEntry,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    //Title
                    Hero(
                      tag: 'title-${widget.entry!.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(labelText: "Title"),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter title";
                            }
                            return null;
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    //Username
                    Hero(
                      tag: 'username-${widget.entry!.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(labelText: "Username"),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: _usernameController.text)
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
                      tag: 'password-${widget.entry!.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(labelText: "Password"),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: _passwordController.text)
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
                    Hero(
                      tag: 'url-${widget.entry!.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: TextFormField(
                          controller: _urlController,
                          decoration: InputDecoration(labelText: "Url"),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    //Notes
                    Hero(
                      tag: 'notes-${widget.entry!.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(labelText: "Notes"),
                          minLines: 4,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/entry.dart';
import 'vault.dart';
import 'alerts.dart';
import 'normalize_url.dart';
import 'generate_password.dart';

class AddEntry extends StatefulWidget {

  final Entry? entry;

  const AddEntry({
    Key? key,
    this.entry
  }): super(key: key);

  @override
  _AddEntryState createState() => _AddEntryState();
}

class _AddEntryState extends State<AddEntry> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _obscurePassword = true;
  bool _hasChanges = false;
  final Vault _dbHelper = Vault();

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _usernameController.text = widget.entry!.username;
      _passwordController.text = widget.entry!.password ?? '';
      _urlController.text = widget.entry!.url ?? '';
      _notesController.text = widget.entry!.notes ?? '';
    }

    //To track changes
    _titleController.addListener(_checkForChanges);
    _usernameController.addListener(_checkForChanges);
    _passwordController.addListener(_checkForChanges);
    _urlController.addListener(_checkForChanges);
    _notesController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final entry = widget.entry;
    final newState =
        _titleController.text != (entry?.title ?? '') ||
        _usernameController.text != (entry?.username ?? '') ||
        _passwordController.text != (entry?.password ?? '') ||
        _urlController.text != (entry?.url ?? '') ||
        _notesController.text != (entry?.notes ?? '');

    if (newState != _hasChanges) {
      setState(() {
        _hasChanges = newState;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
    //Hides keyboard right away
    FocusScope.of(context).unfocus();

      //Auto-correct URL
      String formattedUrl = NormalizeUrl.urlFormatter(_urlController.text);
      
      await _dbHelper.insertEntry(
        _titleController.text, 
        _usernameController.text, 
        _passwordController.text, 
        formattedUrl, 
        _notesController.text,
      );

      //Snackbar message
      final alertsEnabled = context.read<AlertsProvider>().showAlerts;
      if (alertsEnabled && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
        ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Center(
              child: const Text(
                'New Entry Added',
                style: TextStyle(color: Colors.white),
              ),
            ),
            backgroundColor: Colors.green[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      if (context.mounted) Navigator.pop(context, true);
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
        title: const Text('Discard new entry?'),
        content: const Text('You have unsaved entry. Are you sure you want to discard it?'),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
        child: Scaffold(
        appBar: AppBar(
          title: const Text("Add Entry"),
          backgroundColor: const Color(0xFF424242),
          foregroundColor: Colors.white,
          actions: [

            //OK button (i.e. submit button)
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {

                //Submit entry detail
                _submitForm();

              }
            ),

          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const SizedBox(height: 16),

                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: "Title",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter title";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: "Username",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter username";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  minLines: 1,
                  maxLines: _obscurePassword ? 1 : null,
                  decoration: InputDecoration(
                    labelText: "Password",
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

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
                        
                        IconButton(
                          icon: const Icon(Icons.key),
                          tooltip: "Generate Password",
                          onPressed: () async {
                            final generatedPassword = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PasswordGenerator(
                                  existingPassword: _passwordController.text
                                ),
                              ),
                            );
                            if (generatedPassword != null && generatedPassword.isNotEmpty) {
                              setState(() {
                                _passwordController.text = generatedPassword;
                              });
                            }
                          },
                        )
                      ],
                    ),
                    // suffixIcon: IconButton(
                    //   icon: Icon(
                    //     _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    //   ),
                    //   onPressed: () {
                    //     setState(() {
                    //       _obscurePassword = !_obscurePassword;
                    //     });
                    //   },
                    // )
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: "Url",
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  height: 150,
                  child: TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: "Notes",
                    ),
                    minLines: 3,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                ),

                const SizedBox(height: 16),

                /*
                ElevatedButton(
                  onPressed: _submitForm, 
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.amber,
                    foregroundColor: const Color(0xFF212121),
                    minimumSize: const Size(double.infinity, 48),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(fontWeight: FontWeight.w600)
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom
                ),
                */
              ],
            ),
          ),
        ),
      ),
    );
  }
}
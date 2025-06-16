import 'package:flutter/material.dart';
import 'vault.dart';

class AddEntry extends StatefulWidget {

  final Map<String, dynamic>? entry;

  AddEntry({this.entry});

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
  final Vault _dbHelper = Vault();

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!['title'];
      _usernameController.text = widget.entry!['username'];
      _passwordController.text = widget.entry!['password'] ?? '';
      _urlController.text = widget.entry!['url'] ?? '';
      _notesController.text = widget.entry!['notes'] ?? '';
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {

      //Hides keyboard right away
      FocusScope.of(context).unfocus();

      if (widget.entry == null) {
          await _dbHelper.insertEntry(
          _titleController.text, 
          _usernameController.text, 
          _passwordController.text, 
          _urlController.text, 
          _notesController.text,
        );
      } else {
        await _dbHelper.updateEntry(
          widget.entry!['id'],
          _titleController.text,
          _usernameController.text,
          _passwordController.text,
          _urlController.text,
          _notesController.text,
        );
      }

      //Success Message
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text("Entry added"), 
      //     backgroundColor: Colors.green[400],
      //     duration: Duration(seconds: 2),
      //   )
      // );
      Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Entry"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              //Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Title"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter title";
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              //Username
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: "Username"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter username";
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              //Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                ),
              ),

              SizedBox(height: 16),

              //Url
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(labelText: "Url"),
              ),

              SizedBox(height: 16),

              //Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(labelText: "Notes"),
              ),

              SizedBox(height: 20),
              
              //Button
              ElevatedButton(
                onPressed: _submitForm, 
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF085465),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: const StadiumBorder(),
                ),
                child: Text("OK"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
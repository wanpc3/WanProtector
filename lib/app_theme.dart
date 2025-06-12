import 'package:flutter/material.dart';

class AppTheme extends StatelessWidget {
  final VoidCallback toggleTheme;

  AppTheme({required this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Theme'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: toggleTheme, 
          child: Text('Switch Theme'),
        ),
      ),
    );
  }
}
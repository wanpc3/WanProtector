import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class AppTheme extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Theme'),
        backgroundColor: const Color(0xFF0A708A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
              color: isDarkMode ? Colors.amber : Colors.orange,
            ),
            title: Text('Switch to ${isDarkMode ? "Light" : "Dark"} Mode'),
            trailing: Switch(
              value: isDarkMode, 
              onChanged: (value) => themeProvider.toggleTheme(),
              activeColor: Colors.tealAccent,
            ),
          )
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:wan_protector/database_helper.dart';
import 'all_entries.dart';
import 'password_generator.dart';
import 'deleted_entries.dart';
import 'settings.dart';
import 'login_screen.dart';
import 'create_vault.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.light;
  Widget? _initialScreen;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkMasterPassword();
  }

  //Check if user has created master password or not
  void _checkMasterPassword() async {
    final dbHelper = Databasehelper();
    bool isSet = await dbHelper.isMasterPasswordSet();
    setState(() {
      _initialScreen = isSet
        ? LoginScreen(toggleTheme: toggleTheme)
        : CreateVault(toggleTheme: toggleTheme);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: _initialScreen ?? Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  HomeScreen({required this.toggleTheme});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int _selectedIndex = 0;
  late final List<Widget> _pageOptions;

  @override
  void initState() {
    super.initState();
    _pageOptions = [
      AllEntries(),
      PasswordGenerator(),
      DeletedEntries(),
      Settings(toggleTheme: widget.toggleTheme),
    ];
  }

  void _onItemTapped(int index) {
    Navigator.pop(context);
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  final List<String> _titles = [
    'All Entries',
    'Password Generator',
    'Deleted Entries',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),

            //All Entries
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('All Entries'),
              selected: _selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),

            //Password Generator
            ListTile(
              leading: Icon(Icons.password),
              title: Text('Password Generator'),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),

            //Deleted Entries
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Deleted Entries'),
              selected: _selectedIndex == 2,
              onTap: () => _onItemTapped(2),
            ),

            //Settings
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              selected: _selectedIndex == 3,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Settings(
                      toggleTheme: widget.toggleTheme
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pageOptions,
      ),
    );
  }
}

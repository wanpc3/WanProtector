import 'package:flutter/material.dart';
//import 'package:sqflite/sqflite.dart';
import 'vault.dart';
import 'all_entries.dart';
//import 'add_entry.dart';
import 'password_generator.dart';
import 'settings.dart';
import 'login_screen.dart';
import 'get_started.dart';

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

  void _checkMasterPassword() async {
    final dbHelper = Vault();
    bool isSet = await dbHelper.isMasterPasswordSet();
    setState(() {
      _initialScreen = isSet
        ? LoginScreen(toggleTheme: toggleTheme)
        : GetStarted(toggleTheme: toggleTheme);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: _initialScreen ?? Scaffold(
        body: Center(
          child: CircularProgressIndicator()
        )
      ),
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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageOptions = [
      AllEntries(),
      PasswordGenerator(),
      Settings(toggleTheme: widget.toggleTheme),
    ];
  }

  /*
  void _navigateToAddEntry() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AddEntry(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        }
      ),
    );
  }
  */

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
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
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('All Entries'),
              selected: _selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: Icon(Icons.password),
              title: Text('Password Generator'),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
            // ListTile(
            //   leading: Icon(Icons.delete),
            //   title: Text('Deleted Entries'),
            //   selected: _selectedIndex == 2,
            //   onTap: () => _onItemTapped(2),
            // ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              selected: _selectedIndex == 2,
              onTap: () => _onItemTapped(2),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pageOptions,
      ),
      floatingActionButton: _isSearching || _selectedIndex != 0
          ? null
          : FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFF085465),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
    );
  }
}
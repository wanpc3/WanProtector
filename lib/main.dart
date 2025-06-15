import 'package:flutter/material.dart';
import 'all_entries_controller.dart';
import 'vault.dart';
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

  void _checkMasterPassword() async {
    final dbHelper = Vault();
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
  late final GlobalKey<AllEntriesState> _allEntriesKey;
  late final GlobalKey<DeletedEntriesState> _deletedEntriesKey;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  late final AllEntriesController _entriesController;

  @override
  void initState() {
    super.initState();
    _entriesController = AllEntriesController();
    _allEntriesKey = GlobalKey<AllEntriesState>();
    _deletedEntriesKey = GlobalKey<DeletedEntriesState>();
    _pageOptions = [
      AllEntries(
        key: _allEntriesKey,
        controller: _entriesController,
        onEntryDeleted: (id) async {
          await Future.delayed(const Duration(milliseconds: 100), () {
            if (_allEntriesKey.currentState?.mounted ?? false) {
              _allEntriesKey.currentState?.removeEntryWithAnimation(id);
            }
            
            if (_deletedEntriesKey.currentState?.mounted ?? false) {
              _deletedEntriesKey.currentState?.insertNewDeletedEntry(id);
            }
          });
        },
      ),
      PasswordGenerator(),
      DeletedEntries(
        key: _deletedEntriesKey,
        onEntryUpdated: () {
          if (_allEntriesKey.currentState?.mounted ?? false) {
            _allEntriesKey.currentState?.reload();
          }
        },
      ),
      Settings(toggleTheme: widget.toggleTheme),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _entriesController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_isSearching && index != 0) {
      setState(() {
        _isSearching = false;
        _searchController.clear();
        _entriesController.exitSearch?.call();
      });
    }
    
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

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search entries...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: TextStyle(color: Colors.white),
      onChanged: _entriesController.handleSearch,
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_selectedIndex != 0) return [];
    
    return _isSearching
        ? [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _entriesController.exitSearch?.call();
                });
              },
            )
          ]
        : [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            )
          ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching && _selectedIndex == 0 
            ? _buildSearchField()
            : Text(_titles[_selectedIndex]),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: _buildAppBarActions(),
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
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Deleted Entries'),
              selected: _selectedIndex == 2,
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              selected: _selectedIndex == 3,
              onTap: () => _onItemTapped(3),
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
              onPressed: _entriesController.navigateToAddEntry,
              backgroundColor: const Color(0xFF085465),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
    );
  }
}
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'all_entries_controller.dart';
import 'deleted_entries_controller.dart';
import 'vault.dart';
import 'all_entries.dart';
import 'add_entry.dart';
import 'entries_state.dart';
import 'deleted_entries_state_manager.dart';
import 'password_generator.dart';
import 'deleted_entries.dart';
import 'settings.dart';
import 'login_screen.dart';
import 'create_vault.dart';
import 'dart:async';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EntriesState()),
        ChangeNotifierProvider(create: (_) => DeletedEntriesStateManager()),
      ],
      child: MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: _themeMode,
        home: _initialScreen ?? Scaffold(body: Center(child: CircularProgressIndicator())),
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
  late final AllEntriesController _entriesController;
  late final DeletedEntriesController _deletedEntriesController;
  Timer? _searchDebounce;

  //Track which screen is being searched
  int? _searchingScreenIndex;

  @override
  void initState() {
    super.initState();
    _entriesController = AllEntriesController(
      exitSearch: _exitSearch,
      handleSearch: (query) {
        if (_selectedIndex == 0) {
          context.read<EntriesState>().searchEntries(query);
        }
      },
      navigateToAddEntry: _navigateToAddEntry,
    );

    _deletedEntriesController = DeletedEntriesController(
      exitSearch: _exitSearch,
      handleSearch: (query) {
        if (_selectedIndex == 2) {
          context.read<DeletedEntriesStateManager>().searchDeletedEntries(query);
        }
      },
    );
    
    _pageOptions = [
      AllEntries(
        onEntryDeleted: (id) async {
          await Future.delayed(const Duration(milliseconds: 100));
          context.read<EntriesState>().removeEntry(id);
        },
      ),
      PasswordGenerator(),
      DeletedEntries(
        controller: _deletedEntriesController,
        onEntryUpdated: () => context.read<EntriesState>().loadEntries(),
      ),
      Settings(toggleTheme: widget.toggleTheme),
    ];
  }

  void _exitSearch() {
    if (_searchingScreenIndex == 0) {
      context.read<EntriesState>().exitSearch();
    } else if (_searchingScreenIndex == 2) {
      context.read<DeletedEntriesStateManager>().exitSearch();
    }
    setState(() {
      _isSearching = false;
      _searchingScreenIndex = null;
      _searchController.clear();
    });
  }

  void _navigateToAddEntry() async {
    final result = await Navigator.push(
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

    if (result == true) {
      context.read<EntriesState>().loadEntries();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_isSearching) {
      _exitSearch();
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
        hintText: _selectedIndex == 0 
          ? 'Search entries...' 
          : 'Search deleted entries...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: TextStyle(color: Colors.white),
      onChanged: (query) {
        // Debounce the search
        _searchDebounce?.cancel();
        _searchDebounce = Timer(const Duration(milliseconds: 300), () {
          if (_selectedIndex == 0) {
            _entriesController.handleSearch?.call(query);
          } else if (_selectedIndex == 2) {
            _deletedEntriesController.handleSearch?.call(query);
          }
        });
      },
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_selectedIndex != 0 && _selectedIndex != 2) return [];
    
    return _isSearching
        ? [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: _exitSearch,
            )
          ]
        : [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                  _searchingScreenIndex = _selectedIndex;
                  if (_selectedIndex == 0) {
                    context.read<EntriesState>().exitSearch();
                  } else {
                    context.read<DeletedEntriesStateManager>().exitSearch();
                  }
                });
              },
            )
          ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching && (_selectedIndex == 0 || _selectedIndex == 2)
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
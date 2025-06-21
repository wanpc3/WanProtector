import 'encryption_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lifecycle_watcher.dart';
import 'autolock_state.dart';
import 'theme_provider.dart';
import 'entries_state.dart';
import 'deleted_state.dart';
import 'vault.dart';
import 'all_entries.dart';
import 'add_entry.dart';
import 'deleted_entries.dart';
import 'password_generator.dart';
import 'settings.dart';
import 'login_screen.dart';
import 'get_started.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await EncryptionHelper.initialize();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EntriesState()..fetchEntries()),
        ChangeNotifierProvider(create: (_) => DeletedState()..fetchDeletedEntries()),
        ChangeNotifierProvider(create: (_) => AutoLockState()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: LifecycleWatcher(
        onAutoLock: () => handleAutoLock(navigatorKey.currentContext!),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              themeMode: themeProvider.themeMode,
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              home: MainApp(),
            );
          },
        ),
      ),
    ),
  );
}

  void handleAutoLock(BuildContext context) async {
    final dbHelper = Vault();
    bool isMasterPasswordSet = await dbHelper.isMasterPasswordSet();

    if (isMasterPasswordSet) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen(toggleTheme: () {})),
        (route) => false,
      );
    }
  }

class MainApp extends StatefulWidget {
  const MainApp({
    super.key
  });

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {

  Widget? _initialScreen;

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
          ? LoginScreen(toggleTheme: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            })
          : GetStarted(toggleTheme: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _initialScreen ??
        const Scaffold(
          body: Center(
            child: CircularProgressIndicator()
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
      AllEntries(
        isSearching: _isSearching,
        searchController: _searchController,
      ),
      PasswordGenerator(),
      DeletedEntries(
        isSearching: _isSearching,
        searchController: _searchController,
      ),
      Settings(toggleTheme: widget.toggleTheme),
    ];
  }

  //Search Entry
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        if (_selectedIndex == 0) {
          Provider.of<EntriesState>(context, listen: false).fetchEntries();
        } else if (_selectedIndex == 2) {
          Provider.of<DeletedState>(context, listen: false).fetchDeletedEntries();
        }
      }
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
      await Provider.of<EntriesState>(context, listen: false).fetchEntries();
    }
  }

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
        _isSearching = false;
        _searchController.clear();
        
        if (index == 0) {
          _pageOptions[0] = AllEntries(
            isSearching: _isSearching, 
            searchController: _searchController,
          );
        } else if (index == 2) {
          _pageOptions[2] = DeletedEntries(
            isSearching: _isSearching, 
            searchController: _searchController,
          );
        }
      });
    }
  }

  final List<String> _titles = [
    'All Entries',
    'Password Generator',
    'Deleted Entries',
    'Settings',
    'Exit',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching && (_selectedIndex == 0 || _selectedIndex == 2)
            ? TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.black),
                border: InputBorder.none,
              ),
            )
          : Text(_titles[_selectedIndex]),
        backgroundColor: const Color(0xFFB8B8B8),
        foregroundColor: Colors.black,
        actions: (_selectedIndex == 0 || _selectedIndex == 2)
            ? [
              if (_isSearching)
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: _toggleSearch,
                )
              else
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _toggleSearch,
                )
            ]
          : [],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: const Color(0xFFB8B8B8)),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                  "WanProtector",
                    style: TextStyle(
                      color: Colors.black, 
                      fontSize: 30,
                      fontFamily: 'Ubuntu',
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.folder,
                color: Colors.blue,
              ),
              title: Text('All Entries'),
              selected: _selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: Icon(
                Icons.password,
                color: Colors.yellow,
              ),
              title: Text('Password Generator'),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Colors.red
              ),
              title: Text('Deleted Entries'),
              selected: _selectedIndex == 2,
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: Colors.grey,
              ),
              title: Text('Settings'),
              selected: _selectedIndex == 3,
              onTap: () => _onItemTapped(3),
            ),
            ListTile(
              leading: Icon(
                Icons.exit_to_app,
                color: Colors.green,
              ),
              title: Text('Exit Vault'),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 300),
                    pageBuilder: (_, __, ___) => LoginScreen(toggleTheme: () {}),
                    transitionsBuilder: (_, animation, __, child) {
                      final offset = Tween<Offset>(
                        begin: Offset(0, -1),
                        end: Offset.zero,
                      ).animate(animation);
                      return SlideTransition(position: offset, child: child);
                    },
                  ),
                  (route) => false,
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
      floatingActionButton: _isSearching || _selectedIndex != 0
          ? null
          : FloatingActionButton(
              onPressed: _navigateToAddEntry,
              backgroundColor: Color(0xFFB8B8B8),
              foregroundColor: Colors.black,
              child: const Icon(Icons.add),
            ),
    );
  }
}
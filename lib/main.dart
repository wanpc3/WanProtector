import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'encryption_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lifecycle_watcher.dart';
import 'auto_lock.dart';
import 'entries_state.dart';
import 'deleted_state.dart';
import 'alerts.dart';
import 'sort_provider.dart';
import 'vault.dart';
import 'all_entries.dart';
import 'add_entry.dart';
import 'deleted_entries.dart';
import 'password_generator.dart';
import 'settings.dart';
import 'login_screen.dart';
import 'get_started.dart';
import 'screenshot_util.dart';
import 'app_update.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final allowScreenshot = prefs.getBool('allowScreenshot') ?? false;
  toggleScreenshot(allowScreenshot);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await EncryptionHelper.initialize();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EntriesState()..fetchEntries()),
        ChangeNotifierProvider(create: (_) => DeletedState()..fetchDeletedEntries()),
        ChangeNotifierProvider(create: (_) => AlertsProvider()),
        ChangeNotifierProvider(create: (_) => AutoLockState()),
        ChangeNotifierProvider(create: (_) => SortProvider()),
      ],
      child: LifecycleWatcher(
        onAutoLock: () => handleAutoLock(navigatorKey.currentContext!),
        child: Consumer(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              navigatorKey: navigatorKey,
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
      final prefs = await SharedPreferences.getInstance();
      final allowScreenshot = prefs.getBool('allowScreenshot') ?? false;
      toggleScreenshot(allowScreenshot);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
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
          ? LoginScreen()
          : GetStarted();
    });

    //Check for app update
    try {
      checkForUpdate();
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
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

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _lastBackPressed;
  int _selectedIndex = 0;
  late final List<Widget> _pageOptions;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

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
      Settings(),
    ];
  }

  //Search Entry
  void _toggleSearch() async {
    final hadQuery = _searchController.text.isNotEmpty;
    
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching && hadQuery) {
        _searchController.clear();
      }
    });

    if (_isSearching) {
      await Future.delayed(Duration(milliseconds: 100));
      _searchFocusNode.requestFocus();
    }

    if (!_isSearching && hadQuery) {
      try {
        if (_selectedIndex == 0) {
          context.read<EntriesState>().resetSearch();
          await context.read<EntriesState>().fetchEntries();
        } else if (_selectedIndex == 2) {
          context.read<DeletedState>().resetSearch();
          await context.read<DeletedState>().fetchDeletedEntries();
        }
      } catch (e) {
        debugPrint('Error resetting search: $e');
      }
    }
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
    _searchFocusNode.dispose();
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

  //Title in Drawer
  final List<String> _titles = [
    'All Entries',
    'Password Generator',
    'Deleted Entries',
    'Settings',
    'Exit',
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        final isExiting = _lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2);

        if (isExiting) {
          _lastBackPressed = now;
          final alertsEnabled = context.read<AlertsProvider>().showAlerts;
          if (alertsEnabled && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Press back again to exit and log out'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          return false;
        }

        //Now log out and exit
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(-1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
                );
              }
            ),
          (route) => false,
        );
        return true;
      },
      child: Scaffold(

        //Appbar
        appBar: AppBar(
          title: _isSearching && (_selectedIndex == 0 || _selectedIndex == 2)
              ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : Text(_titles[_selectedIndex]),
          backgroundColor: const Color(0xFF424242),
          foregroundColor: Colors.white,
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
                decoration: BoxDecoration(color: const Color(0xFF424242)),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text(
                    "WanProtector",
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 30,
                        fontFamily: 'Ubuntu',
                      ),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  _selectedIndex == 0 ? Icons.folder : Icons.folder_outlined,
                  color: Colors.blue,
                ),
                title: const Text('All Entries'),
                selected: _selectedIndex == 0,
                onTap: () => _onItemTapped(0),
              ),
              ListTile(
                leading: Icon(
                  _selectedIndex == 1 ? Icons.password : Icons.password_outlined,
                  color: Colors.amber[600],
                ),
                title: const Text('Password Generator'),
                selected: _selectedIndex == 1,
                onTap: () => _onItemTapped(1),
              ),
              ListTile(
                leading: Icon(
                  _selectedIndex == 2 ? Icons.delete : Icons.delete_outline,
                  color: Colors.blueGrey
                ),
                title: const Text('Deleted Entries'),
                selected: _selectedIndex == 2,
                onTap: () => _onItemTapped(2),
              ),
              ListTile(
                leading: Icon(
                  _selectedIndex == 3 ? Icons.settings : Icons.settings_outlined,
                  color: Colors.grey,
                ),
                title: const Text('Settings'),
                selected: _selectedIndex == 3,
                onTap: () => _onItemTapped(3),
              ),
              ListTile(
                leading: Icon(
                  Icons.exit_to_app_outlined,
                  color: Colors.redAccent,
                ),
                title: const Text('Exit Vault'),
                onTap: () async {

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Exit Vault?'),
                      content: const Text('You will be logged out from the vault. Do you wish to proceed?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false), 
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Proceed'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    Navigator.of(context).pushAndRemoveUntil(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(-1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;
                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        }
                      ),
                      (route) => false,
                    );
                  }
                  
                  // Navigator.of(context).pushAndRemoveUntil(
                  //   PageRouteBuilder(
                  //     transitionDuration: Duration(milliseconds: 300),
                  //     pageBuilder: (_, __, ___) => LoginScreen(),
                  //     transitionsBuilder: (_, animation, __, child) {
                  //       final offset = Tween<Offset>(
                  //         begin: Offset(0, -1),
                  //         end: Offset.zero,
                  //       ).animate(animation);
                  //       return SlideTransition(position: offset, child: child);
                  //     },
                  //   ),
                  //   (route) => false,
                  // );
                },
              ),
            ],
          ),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pageOptions,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: _isSearching || _selectedIndex != 0
            ? null
            : FloatingActionButton(
                onPressed: _navigateToAddEntry,
                backgroundColor: Colors.amber,
                foregroundColor: const Color(0xFF212121),
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}
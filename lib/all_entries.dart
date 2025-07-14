import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/entry.dart';
import 'vault.dart';
import 'entries_state.dart';
import 'deleted_state.dart';
import 'view_entry.dart';
import 'edit_entry.dart';
import 'sort_provider.dart';
import 'alerts.dart';

class AllEntries extends StatefulWidget {
  final bool isSearching;
  final TextEditingController searchController;
  final VoidCallback? onSearchToggled;

  const AllEntries({
    Key? key,
    required this.isSearching,
    required this.searchController,
    this.onSearchToggled,
  }) : super(key: key);

  @override
  AllEntriesState createState() => AllEntriesState();
}

class AllEntriesState extends State<AllEntries> {
  Timer? _searchDebounce;
  bool _showSwipeTip = true;
  //bool _hideSwipeTip = false;

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);

    SharedPreferences.getInstance().then((prefs) {
      final hasSeenTip = prefs.getBool('hasSeenSwipeTip') ?? false;
      setState(() {
        _showSwipeTip = !hasSeenTip;
      });
    });
  }
  
  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final query = widget.searchController.text;

      if (query.isEmpty) {
        if (context.read<EntriesState>().searchText.isNotEmpty) {
          context.read<EntriesState>().fetchEntries();
        }
      } else {
        context.read<EntriesState>().searchEntries(query);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  //To go View Entry
  void _navigateToViewEntry(Entry entry) async {
    final fullEntry = await Vault().getEntryById(entry.id!);
    if (fullEntry == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewEntry(entry: entry),
      ),
      // PageRouteBuilder(
      //   pageBuilder: (_, __, ___) => ViewEntry(entry: fullEntry),
      //   transitionsBuilder: (context, animation, secondaryAnimation, child) {
      //     return ScaleTransition(
      //       scale: animation.drive(CurveTween(curve: Curves.fastOutSlowIn)),
      //       child: FadeTransition(opacity: animation, child: child),
      //     );
      //   },
      //   transitionDuration: Duration(milliseconds: 400),
      // ),
    );

    if (result == true) {
      context.read<EntriesState>().fetchEntries();
    }
  }

  //To go Edit Entry
  void _navigateToEditEntry(Entry entry) async {
    final fullEntry = await Vault().getEntryById(entry.id!);
    if (fullEntry == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEntry(entry: entry),
      ),
    );

    if (result == true) {
      context.read<EntriesState>().fetchEntries();
    }
  }

  Widget _buildSwipeTipCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.gesture, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Swipe to manage', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text('Swipe left on entries to reveal actions', 
                    style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: _dismissTip,
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dismissTip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenSwipeTip', true);
    if (mounted) {
      setState(() {
        _showSwipeTip = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesProvider = Provider.of<EntriesState>(context);
    final sortProvider = Provider.of<SortProvider>(context);

    List<Entry> sortedEntries = [...entriesProvider.entries];

    if (sortProvider.sortMode == 'Title (A-Z)') {
      sortedEntries.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (sortProvider.sortMode == 'Username (A-Z)') {
      sortedEntries.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
    } else if (sortProvider.sortMode == 'Last Updated') {
      sortedEntries.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    } else {
      sortedEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return Scaffold(
      body: Column(
        children: [
          if (entriesProvider.isLoading && widget.isSearching)
            const LinearProgressIndicator(minHeight: 2),

          //Tooltip
          if (_showSwipeTip && sortedEntries.isNotEmpty)
            Dismissible(
              key: const Key('swipe_tip'),
              direction: DismissDirection.horizontal,
              onDismissed: (_) => _dismissTip(),
              background: Container(color: Colors.transparent),
              child: _buildSwipeTipCard(),
            ),

          Expanded(
            child: sortedEntries.isEmpty
                ? Center(
                    child: Text(
                      "No Entries Available",
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedEntries.length,
                    itemBuilder: (context, index) {

                      final entry = sortedEntries[index];

                      return Column(
                        children: [
                          Slidable(
                            key: ValueKey(entry.id),
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              extentRatio: 0.5,
                              children: [
                                SlidableAction(
                                  onPressed: (_) => _navigateToEditEntry(entry),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  icon: Icons.edit,
                                  label: 'Edit',
                                ),
                                SlidableAction(
                                  onPressed: (_) async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Entry?'),
                                        content: Text('${entry.title} will be moved to Deleted Entries page'),
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
                                      await Vault().softDeleteEntry(entry.id!);
                                      await context.read<EntriesState>().refreshEntries();
                                      await context.read<DeletedState>().refreshDeletedEntries();

                                      //Snackbar message
                                      final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                                      if (alertsEnabled && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${entry.title} moved to Deleted Entries',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                            backgroundColor: Colors.red[400],
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: 'Delete',
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.key, color: Colors.amber),
                              title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(entry.username, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: Text(
                                _formatDate(entry.createdAt),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              onTap: () => _navigateToViewEntry(entry),
                            ),
                          ),
                          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } catch (e) {
      return isoString;
    }
  }
}
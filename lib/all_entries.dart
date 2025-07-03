import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/entry.dart';
import 'vault.dart';
import 'entries_state.dart';
import 'view_entry.dart';
import 'sort_provider.dart';

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

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
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

  @override
  Widget build(BuildContext context) {

    final entriesProvider = Provider.of<EntriesState>(context);
    final sortProvider = Provider.of<SortProvider>(context);

    List <Entry> sortedEntries = [...entriesProvider.entries];

    if (sortProvider.sortMode == 'Title (A-Z)') {
      sortedEntries.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (sortProvider.sortMode == 'Username (A-Z)') {
      sortedEntries.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
    } else if (sortProvider.sortMode == 'Last Updated') {
      sortedEntries.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    } else {
      //Recently Added
      sortedEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return Scaffold(
      body: Column(
        children: [
          if (entriesProvider.isLoading && widget.isSearching)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: entriesProvider.entries.isEmpty
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
                        ListTile(
                          leading: Icon(Icons.key_outlined, color: Colors.amber),
                          title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(entry.username, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Text(
                            _formatDate(entry.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          onTap: () => _navigateToViewEntry(entry),
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
}

String _formatDate(String isoString) {
  try {
    final dateTime = DateTime.parse(isoString);
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  } catch (e) {
    return isoString;
  }
}

import 'dart:async';
import 'package:WanProtector/vault.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/deleted_entry.dart';
import 'deleted_state.dart';
import 'view_deleted_entry.dart';
import 'sort_provider.dart';

class DeletedEntries extends StatefulWidget {
  final bool isSearching;
  final TextEditingController searchController;
  final VoidCallback? onSearchToggled;

  const DeletedEntries({
    Key? key,
    required this.isSearching,
    required this.searchController,
    this.onSearchToggled,
  }) : super(key: key);

  @override
  DeletedEntriesState createState() => DeletedEntriesState();
}

class DeletedEntriesState extends State<DeletedEntries> {
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
        if (context.read<DeletedState>().searchText.isNotEmpty) {
          context.read<DeletedState>().fetchDeletedEntries();
        }
      } else {
        context.read<DeletedState>().searchDeletedEntries(query);
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
  void _navigateToViewDeletedEntry(DeletedEntry deletedEntry) async {
    final fullDeletedEntry = await Vault().getDeletedEntryById(deletedEntry.deletedId!);
    if (fullDeletedEntry == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewDeletedEntry(deletedEntry: fullDeletedEntry)
      ),
      // PageRouteBuilder(
      //   pageBuilder: (_, __, ___) => ViewDeletedEntry(
      //     deletedEntry: fullDeletedEntry,
      //   ),
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
      context.read<DeletedState>().fetchDeletedEntries();
    }
  }

  @override
  Widget build(BuildContext context) {

    final deletedEntriesProvider = Provider.of<DeletedState>(context);
    final sortProvider = Provider.of<SortProvider>(context);

    List <DeletedEntry> sortedDeletedEntries = [...deletedEntriesProvider.deletedEntries];

    if (sortProvider.sortMode == 'Title (A-Z)') {
      sortedDeletedEntries.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (sortProvider.sortMode == 'Username (A-Z)') {
      sortedDeletedEntries.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
    } else if (sortProvider.sortMode == 'Last Updated') {
      sortedDeletedEntries.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    } else {
      //Recently Added
      sortedDeletedEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return Scaffold(
      body: Column(
        children: [
          if (deletedEntriesProvider.isLoading && widget.isSearching)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: deletedEntriesProvider.deletedEntries.isEmpty
              ? Center(
                  child: Text(
                    "No Deleted Entries Available",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  itemCount: sortedDeletedEntries.length,
                  itemBuilder: (context, index) {
                    final deletedEntry = sortedDeletedEntries[index];
                    return Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.close, color: Colors.red),
                          title: Text(deletedEntry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(deletedEntry.username, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Text(
                            _formatDate(deletedEntry.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          onTap: () => _navigateToViewDeletedEntry(deletedEntry),
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

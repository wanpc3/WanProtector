import 'package:WanProtector/vault.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/deleted_entry.dart';
import 'deleted_state.dart';
import 'view_deleted_entry.dart';

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

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = widget.searchController.text;
    if (query.isNotEmpty) {
      context.read<DeletedState>().searchDeletedEntries(query);
    } else {
      context.read<DeletedState>().fetchDeletedEntries();
    }
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  //To go View Entry
  void _navigateToViewDeletedEntry(DeletedEntry deletedEntry) async {
    final fullDeletedEntry = await Vault().getDeletedEntryById(deletedEntry.deletedId!);
    if (fullDeletedEntry == null) return;

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ViewDeletedEntry(
          deletedEntry: fullDeletedEntry,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: animation.drive(CurveTween(curve: Curves.fastOutSlowIn)),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );

    if (result == true) {
      context.read<DeletedState>().fetchDeletedEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deletedEntriesProvider = Provider.of<DeletedState>(context);

    return Scaffold(
      body: deletedEntriesProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: deletedEntriesProvider.deletedEntries.length,
              separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.5, color: Colors.grey),
              itemBuilder: (context, index) {
                final deletedEntry = deletedEntriesProvider.deletedEntries[index];
                return ListTile(
                  leading: Icon(Icons.close, color: Colors.red),
                  title: Text(deletedEntry.title),
                  subtitle: Text(deletedEntry.username),
                  trailing: Text(
                    _formatDate(deletedEntry.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () => _navigateToViewDeletedEntry(deletedEntry),
                );
              },
            )
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

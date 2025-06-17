import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  void _navigateToViewDeletedEntry(Map<String, dynamic> deletedEntry) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ViewDeletedEntry(
          deletedId: deletedEntry['deleted_id'],
        ),
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
      context.read<DeletedState>().fetchDeletedEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deletedEntriesProvider = Provider.of<DeletedState>(context);
    return Scaffold(
      body: deletedEntriesProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: deletedEntriesProvider.deletedEntries.length,
              itemBuilder: (context, index) {
                final deletedEntry = deletedEntriesProvider.deletedEntries[index];
                return Column(
                  children: [
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey[300],
                    ),
                    ListTile(
                      leading: Icon(Icons.close, color: Colors.red),
                      title: Text(deletedEntry.title),
                      subtitle: Text(deletedEntry.username),
                      trailing: Text(
                        _formatDate(deletedEntry.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      onTap: () async {
                        final mappedDeletedEntry = await deletedEntry.toMapAsync();
                        _navigateToViewDeletedEntry(mappedDeletedEntry);
                      },
                    ),
                    if (index == deletedEntriesProvider.deletedEntries.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey[300],
                      ),
                  ],
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

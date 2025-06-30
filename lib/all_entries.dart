import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/entry.dart';
import 'vault.dart';
import 'entries_state.dart';
import 'view_entry.dart';

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

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = widget.searchController.text;
    if (query.isNotEmpty) {
      context.read<EntriesState>().searchEntries(query);
    } else {
      context.read<EntriesState>().fetchEntries();
    }
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  //To go View Entry
  void _navigateToViewEntry(Entry entry) async {
    final fullEntry = await Vault().getEntryById(entry.id!);
    if (fullEntry == null) return;

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ViewEntry(entry: fullEntry),
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
      context.read<EntriesState>().fetchEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesProvider = Provider.of<EntriesState>(context);

    return Scaffold(
      body: entriesProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : entriesProvider.entries.isEmpty
            ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      "No Entries Available",
                        style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: entriesProvider.entries.length,
              itemBuilder: (context, index) {
                final entry = entriesProvider.entries[index];
                // final backgroundColor = index.isEven
                //     ? const Color(0xFFEFEFFF)
                //     : Colors.transparent;

                return Column(
                  children: [
                    Container(
                      //color: backgroundColor,
                      child: ListTile(
                        leading: Icon(Icons.key_outlined, color: Colors.amber),
                        title: Text(
                          entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          entry.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          _formatDate(entry.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () => _navigateToViewEntry(entry),
                      ),
                    ),
                    Divider(height: 1, thickness: 0.5, color: Colors.grey),
                  ],
                );
              },
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

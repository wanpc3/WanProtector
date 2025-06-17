import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  void _navigateToViewEntry(Map<String, dynamic> entry) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ViewEntry(
          entryId: entry['id'],
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
      context.read<EntriesState>().fetchEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesProvider = Provider.of<EntriesState>(context);

    return Scaffold(
      body: entriesProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: entriesProvider.entries.length,
              itemBuilder: (context, index) {
                final entry = entriesProvider.entries[index];
                return Column(
                  children: [
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey[300],
                    ),
                    ListTile(
                      leading: Icon(Icons.key, color: Colors.amber),
                      title: Text(entry.title),
                      subtitle: Text(entry.username),
                      trailing: Text(
                        _formatDate(entry.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      onTap: () => _navigateToViewEntry(entry.toMap()),
                    ),
                    if (index == entriesProvider.entries.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey[300],
                      ),
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

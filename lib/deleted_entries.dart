import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'deleted_state.dart';
import 'view_deleted_entry.dart';

class DeletedEntries extends StatefulWidget {

  const DeletedEntries({
    Key? key,
  });

  @override
  DeletedEntriesState createState() => DeletedEntriesState();
}

class DeletedEntriesState extends State<DeletedEntries> {

  //To go View Entry
  void _navigateToViewDeletedEntry(Map<String, dynamic> entry) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ViewDeletedEntry(
          oldId: entry['deleted_id'],
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
                final entry = deletedEntriesProvider.deletedEntries[index];
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
                      onTap: () => _navigateToViewDeletedEntry(entry.toMap()),
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

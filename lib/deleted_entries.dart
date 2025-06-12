import 'package:flutter/material.dart';
import 'view_deleted_entry.dart';
import 'database_helper.dart';

class DeletedEntries extends StatefulWidget {
  @override
  _DeletedEntriesState createState() => _DeletedEntriesState();
}

class _DeletedEntriesState extends State<DeletedEntries> {
  final Databasehelper _dbHelper = Databasehelper();
  List<Map<String, dynamic>> _deletedEntries = [];

  @override
  void initState() {
    super.initState();
    _loadDeletedEntries();
  }

  void _loadDeletedEntries() async {
    final deletedEntries = await _dbHelper.getDeletedEntries();
    setState(() {
      _deletedEntries = deletedEntries;
    });
  }

  void _deleteEntryPermanently(int id) async {
    await _dbHelper.deleteEntryPermanently(id);
    setState(() {
      _deletedEntries.removeWhere((entry) => entry['deleted_id'] == id);
    });
  }

  //To view deleted entry
  void _navigateToViewDeletedEntry(Map<String, dynamic> oldEntry) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewDeletedEntry(
          oldId: oldEntry['deleted_id'],
          onRestored: _loadDeletedEntries,
        )
      ),
    );
    
    if (result == true) {
      _loadDeletedEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _deletedEntries.isEmpty
          ? Center(
            child: Text(
              'No deleted entries.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ): ListView.builder(
          itemCount: _deletedEntries.length,
          itemBuilder: (context, index) {
            final deletedEntry = _deletedEntries[index];
            return ListTile(
              key: ValueKey(deletedEntry['deleted_id']),
              leading: Icon(Icons.close, color: Colors.red),
              title: Text(deletedEntry['title']),
              subtitle: Text(deletedEntry['username']),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Permanently Delete?'),
                      content: Text('This action cannot be undone. Are you sure?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false), 
                          child: Text('Cancel')
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true), 
                          child: Text('Delete')
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    _deleteEntryPermanently(deletedEntry['deleted_id']);
                  }
                },
              ),
              onTap: () => _navigateToViewDeletedEntry(deletedEntry),
            );
        },
      ),
    );
  }
}
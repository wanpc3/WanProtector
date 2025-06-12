import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'add_entry.dart';
import 'view_entry.dart';

class AllEntries extends StatefulWidget {
  @override
  _AllEntriesState createState() => _AllEntriesState();
}

class _AllEntriesState extends State<AllEntries> {
  final Databasehelper _dbHelper = Databasehelper();
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _loadEntries() async {
    final entries = await _dbHelper.getEntries();
    setState(() {
      _entries = entries;
    });
  }

  //To add entry form
  void _navigateToAddEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEntry()
      ),
    );

    if (result == true) {
      _loadEntries();
    }
  }

  //To view entry
  void _navigateToViewEntry(Map<String, dynamic> entry) async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => ViewEntry(
          entryId: entry['id'],
          onEntryUpdated: _loadEntries,
        ),
      ),
    );

    if (result == true) {
      _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _entries.isEmpty
      ? Center(
          child: Text(
            'No entries found.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        )
      : ListView.builder(
          itemCount: _entries.length,
          itemBuilder: (context, index) {
            final entry = _entries[index];
            return ListTile(
              leading: Icon(Icons.key, color: Colors.amber),
              title: Text(entry['title']),
              subtitle: Text(entry['username']),
              trailing: Text(
                _formatDate(entry['created_at']),
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              onTap: () => _navigateToViewEntry(entry),
            );
          },
        ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddEntry,
        backgroundColor: const Color(0xFF085465),
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('Add Entry'),
      ),
    );
  }
}

String _formatDate(String isoString) {
  final dateTime = DateTime.parse(isoString);
  return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
}
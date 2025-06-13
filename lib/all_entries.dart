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
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadEntries();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
          if (_hasMore && !_isLoading) {
            _loadMoreEntries();
          }
        }
  }

  void _loadEntries() async {
    setState(() => _isLoading = true);
    _currentPage = 0;
    final entries = await _dbHelper.getEntriesPaginated(_itemsPerPage, 0);
    setState(() {
      _entries = entries;
      _isLoading = false;
      _hasMore = entries.length == _itemsPerPage;
    });
  }

  void _loadMoreEntries() async {
    if (!_hasMore || _isLoading) return;

    setState(() => _isLoading = true);
    _currentPage++;
    final newEntries = await _dbHelper.getEntriesPaginated(
      _itemsPerPage,
      _currentPage * _itemsPerPage
    );

    setState(() {
      _isLoading = false;
      if (newEntries.isNotEmpty) {
        _entries.addAll(newEntries);
        _hasMore = newEntries.length == _itemsPerPage;
      } else {
        _hasMore = false;
      }
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
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ViewEntry(
          entryId: entry['id'],
          onEntryUpdated: _loadEntries,
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
      _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading && _entries.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Text(
                    'No entries found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    if (scrollNotification is ScrollEndNotification &&
                        _scrollController.position.extentAfter == 0) {
                      if (_hasMore && !_isLoading) {
                        _loadMoreEntries();
                      }
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _entries.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _entries.length) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
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
                ),

      //FAB: FLoating Action Button  
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddEntry,
        backgroundColor: const Color(0xFF085465),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

String _formatDate(String isoString) {
  final dateTime = DateTime.parse(isoString);
  return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
}
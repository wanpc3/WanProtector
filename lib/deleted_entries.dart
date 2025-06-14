import 'package:flutter/material.dart';
import 'view_deleted_entry.dart';
import 'database_helper.dart';

class DeletedEntries extends StatefulWidget {
  final VoidCallback? onEntryUpdated;

  const DeletedEntries({
    Key? key,
    this.onEntryUpdated
  }) : super(key: key);

  @override
  DeletedEntriesState createState() => DeletedEntriesState();
}

class DeletedEntriesState extends State<DeletedEntries> {
  final Databasehelper _dbHelper = Databasehelper();
  List<Map<String, dynamic>> _deletedEntries = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadDeletedEntries();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDeletedEntries();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void reload() {
    _loadDeletedEntries();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
      _scrollController.position.maxScrollExtent) {
        if (_hasMore && !_isLoading) {
          _loadMoreDeletedEntries();
        }
      }
  }

  void _loadDeletedEntries() async {
    setState(() => _isLoading = true);
    _currentPage = 0;
    final deletedEntries = await _dbHelper.getDeletedEntriesPaginated(
      _itemsPerPage,
      0
    );
    setState(() {
      _deletedEntries = deletedEntries;
      _isLoading = false;
      _hasMore = deletedEntries.length == _itemsPerPage;
    });
  }

  void _loadMoreDeletedEntries() async {
    if (!_hasMore || _isLoading) return;

    setState(() => _isLoading = true);
    _currentPage++;
    final newEntries = await _dbHelper.getDeletedEntriesPaginated(
      _itemsPerPage,
      _currentPage * _itemsPerPage
    );

    setState(() {
      _isLoading = false;
      if (newEntries.isNotEmpty) {
        _deletedEntries.addAll(newEntries);
        _hasMore = newEntries.length == _itemsPerPage;
      } else {
        _hasMore = false;
      }
    });
  }

  //To view deleted entry
  void _navigateToViewDeletedEntry(Map<String, dynamic> oldEntry) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ViewDeletedEntry(
          oldId: oldEntry['deleted_id'],
          onRestored: _loadDeletedEntries,
          onEntryUpdated: widget.onEntryUpdated,
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
      _loadDeletedEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading && _deletedEntries.isEmpty
        ? Center(child: CircularProgressIndicator())
        : _deletedEntries.isEmpty
            ? Center(
              child: Text(
                'No deleted entries.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ): NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification) {
                if (ScrollNotification is ScrollEndNotification &&
                    _scrollController.position.extentAfter == 0) {
                      if (_hasMore && !_isLoading) {
                        _loadMoreDeletedEntries();
                      }
                    }
                  return false;
                },
                child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _deletedEntries.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      final deletedEntry = _deletedEntries[index];
                      return ListTile(
                        key: ValueKey(deletedEntry['deleted_id']),
                        leading: Icon(Icons.close, color: Colors.red),
                        title: Text(deletedEntry['title']),
                        subtitle: Text(deletedEntry['username']),
                        trailing: Text(
                          _formatDate(deletedEntry['created_at']),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () => _navigateToViewDeletedEntry(deletedEntry),
                      );
                  },
              ),
            ),
    );
  }
}

String _formatDate(String isoString) {
  final dateTime = DateTime.parse(isoString);
  return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
}
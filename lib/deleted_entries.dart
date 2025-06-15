import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:wan_protector/deleted_entries_controller.dart';
import 'deleted_entries_state_manager.dart';
import 'view_deleted_entry.dart';

class DeletedEntries extends StatefulWidget {
  final VoidCallback? onEntryUpdated;
  final DeletedEntriesController? controller;

  const DeletedEntries({
    Key? key,
    this.controller,
    this.onEntryUpdated,
  }) : super(key: key);

  @override
  DeletedEntriesState createState() => DeletedEntriesState();
}

class DeletedEntriesState extends State<DeletedEntries> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    widget.controller?.exitSearch = _exitSearch;
    widget.controller?.handleSearch = _handleSearch;
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeletedEntriesStateManager>().loadDeletedEntries();
    });
  }

  void _exitSearch() {
    context.read<DeletedEntriesStateManager>().exitSearch();
  }

  void _handleSearch(String query) {
    context.read<DeletedEntriesStateManager>().searchDeletedEntries(query);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final state = context.read<DeletedEntriesStateManager>();
      if (state.hasMore && !state.isLoading) {
        state.loadMoreDeletedEntries();
      }
    }
  }

  void _navigateToViewDeletedEntry(Map<String, dynamic> deletedEntry) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ViewDeletedEntry(
          oldId: deletedEntry['deleted_id'],
          onRestored: () {
            context.read<DeletedEntriesStateManager>().deleteEntry(deletedEntry['deleted_id']);
            widget.onEntryUpdated?.call();
          },
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
    
    if (result == true && mounted) {
      context.read<DeletedEntriesStateManager>().loadDeletedEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeletedEntriesStateManager>(
      builder: (context, state, child) {
        return Scaffold(
          body: state.isLoading && state.filteredDeletedEntries.isEmpty
              ? Center(child: CircularProgressIndicator())
              : state.filteredDeletedEntries.isEmpty
                  ? Center(
                      child: Text(
                        state.isSearching ? 'No results found' : 'No deleted entries found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
                        if (scrollNotification is ScrollEndNotification &&
                            _scrollController.position.extentAfter == 0) {
                          if (state.hasMore && !state.isLoading) {
                            state.loadMoreDeletedEntries();
                          }
                        }
                        return false;
                      },
                      child: AnimatedList(
                        key: _listKey,
                        controller: _scrollController,
                        initialItemCount: state.filteredDeletedEntries.length,
                        itemBuilder: (context, index, animation) {
                          if (index >= state.filteredDeletedEntries.length) {
                            return SizedBox.shrink();
                          }
                          final entry = state.filteredDeletedEntries[index];
                          return _buildAnimatedItem(entry, animation, index);
                        },
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildAnimatedItem(
    Map<String, dynamic> entry,
    Animation<double> animation,
    int index,
  ) {
    final state = context.read<DeletedEntriesStateManager>();
    
    return SizeTransition(
      sizeFactor: animation,
      child: Column(
        children: [
          Divider(height: 1, thickness: 0.5),
          ListTile(
            key: ValueKey(entry['deleted_id']),
            leading: Icon(Icons.close, color: Colors.red),
            title: Text(entry['title'] ?? 'No Title'),
            subtitle: Text(entry['username'] ?? 'No Username'),
            trailing: Text(
              _formatDate(entry['created_at']),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () => _navigateToViewDeletedEntry(entry),
          ),
          if (index == state.filteredDeletedEntries.length - 1 && state.hasMore)
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          Divider(height: 1, thickness: 0.5),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } catch (e) {
      return isoString;
    }
  }
}
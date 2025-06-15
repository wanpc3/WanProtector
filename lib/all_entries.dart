import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wan_protector/all_entries_controller.dart';
import 'entries_state.dart';
import 'view_entry.dart';

class AllEntries extends StatefulWidget {
  final Function(int)? onEntryDeleted;
  final AllEntriesController? controller;

  const AllEntries({
    Key? key,
    this.controller,
    this.onEntryDeleted,
  }) : super(key: key);

  @override
  AllEntriesState createState() => AllEntriesState();
}

class AllEntriesState extends State<AllEntries> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EntriesState>().loadEntries();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      final state = context.read<EntriesState>();
      if (state.hasMore && !state.isLoading && !state.isSearching) {
        state.loadMoreEntries();
      }
    }
  }

  void _navigateToViewEntry(Map<String, dynamic> entry) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ViewEntry(
          entryId: entry['id'],
          onEntryUpdated: () => context.read<EntriesState>().loadEntries(),
          onEntryDeleted: (id) {
            context.read<EntriesState>().removeEntry(id);
            widget.onEntryDeleted?.call(id);
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

    if (result == true) {
      context.read<EntriesState>().loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EntriesState>(
      builder: (context, state, child) {
        return Scaffold(
          body: state.isLoading && state.filteredEntries.isEmpty
              ? Center(child: CircularProgressIndicator())
              : state.filteredEntries.isEmpty
                  ? Center(
                      child: Text(
                        state.isSearching ? 'No results found' : 'No entries found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
                        if (scrollNotification is ScrollEndNotification &&
                            _scrollController.position.extentAfter == 0) {
                          if (state.hasMore && !state.isLoading && !state.isSearching) {
                            state.loadMoreEntries();
                          }
                        }
                        return false;
                      },
                      child: AnimatedList(
                        key: _listKey,
                        controller: _scrollController,
                        initialItemCount: state.filteredEntries.length,
                        itemBuilder: (context, index, animation) {
                          if (index >= state.filteredEntries.length) {
                            return SizedBox.shrink();
                          }
                          final entry = state.filteredEntries[index];
                          return _buildAnimatedItem(entry, animation);
                        },
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildAnimatedItem(Map<String, dynamic> entry, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Column(
        children: [
          Divider(height: 1, thickness: 0.5),
          ListTile(
            key: ValueKey(entry['id']),
            leading: Icon(Icons.key, color: Colors.amber),
            title: Text(entry['title']),
            subtitle: Text(entry['username']),
            trailing: Text(
              _formatDate(entry['created_at']),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () => _navigateToViewEntry(entry),
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
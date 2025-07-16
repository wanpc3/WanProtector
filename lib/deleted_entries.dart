import 'dart:async';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'vault.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/deleted_entry.dart';
import 'entries_state.dart';
import 'deleted_state.dart';
import 'view_deleted_entry.dart';
import 'alerts.dart';
import 'sort_provider.dart';
import 'copy_to_clipboard.dart';
import 'normalize_url.dart';

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
  Timer? _searchDebounce;
  final Vault _dbHelper = Vault();

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final query = widget.searchController.text;

      if (query.isEmpty) {
        if (context.read<DeletedState>().searchText.isNotEmpty) {
          context.read<DeletedState>().fetchDeletedEntries();
        }
      } else {
        context.read<DeletedState>().searchDeletedEntries(query);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  //To go View Entry
  void _navigateToViewDeletedEntry(DeletedEntry deletedEntry) async {
    final fullDeletedEntry = await Vault().getDeletedEntryById(deletedEntry.deletedId!);
    if (fullDeletedEntry == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewDeletedEntry(deletedEntry: fullDeletedEntry)
      ),
      // PageRouteBuilder(
      //   pageBuilder: (_, __, ___) => ViewDeletedEntry(
      //     deletedEntry: fullDeletedEntry,
      //   ),
      //   transitionsBuilder: (context, animation, secondaryAnimation, child) {
      //     return ScaleTransition(
      //       scale: animation.drive(CurveTween(curve: Curves.fastOutSlowIn)),
      //       child: FadeTransition(opacity: animation, child: child),
      //     );
      //   },
      //   transitionDuration: Duration(milliseconds: 400),
      // ),
    );

    if (result == true) {
      context.read<DeletedState>().fetchDeletedEntries();
    }
  }

  void _showDeletedEntryActions(BuildContext context, DeletedEntry deletedEntry) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deletedEntry.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(context, 'Username:', deletedEntry.username),
                    _buildDetailRow(context, 'Password:', deletedEntry.password ?? '', obscureText: true),
                    if (deletedEntry.url != null && deletedEntry.url!.isNotEmpty)
                      _buildUrlRow(context, 'URL:', deletedEntry.url!),
                    if (deletedEntry.notes != null && deletedEntry.notes!.isNotEmpty)
                      _buildDetailRow(context, 'Notes:', deletedEntry.notes!),
                  ],
                ),
              ),
              const Divider(),

                //View Entry
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('View Deleted Entry'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToViewDeletedEntry(deletedEntry);
                  },
                ),

                //Copy Username
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy Username'),
                  onTap: () {
                    final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                    if (alertsEnabled && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
                      copyToClipboardWithFeedback(context, '👤', 'Username', deletedEntry.username);
                    } else {
                      Clipboard.setData(ClipboardData(text: deletedEntry.username));
                    }
                    Navigator.pop(context);
                  },
                ),

                //Copy Password
                if (deletedEntry.password != null && deletedEntry.password!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.copy),
                    title: const Text('Copy Password'),
                    onTap: () {
                      final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                      if (alertsEnabled && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
                        copyToClipboardWithFeedback(context, '🔑', 'Password', deletedEntry.password ?? '');
                      } else {
                        Clipboard.setData(ClipboardData(text: deletedEntry.password ?? ''));
                      }
                      Navigator.pop(context);
                    },
                  ),

                //Copy URL
                if (deletedEntry.url != null && deletedEntry.url!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.copy),
                    title: const Text('Copy URL'),
                    onTap: () {
                      final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                      if (alertsEnabled && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
                        copyToClipboardWithFeedback(context, '🔗', 'URL', deletedEntry.url ?? '');
                      } else {
                        Clipboard.setData(ClipboardData(text: deletedEntry.url ?? ''));
                      }
                      Navigator.pop(context);
                    },
                  ),

                //Open URL in Browser
                if (deletedEntry.url != null && deletedEntry.url!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.open_in_browser),
                    title: const Text('Open URL in Browser'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _openUrlInBrowser(context, deletedEntry.url);
                    },
                  ),

                //Restore Entry
                ListTile(
                  leading: const Icon(Icons.restore_from_trash),
                  title: const Text('Restore Entry'),
                  onTap: () async {
                    await _dbHelper.restoreEntry(deletedEntry.deletedId!);
                    
                    //Refresh the deleted entry so it updates.
                    final stateDeletedManager = context.read<DeletedState>();
                    await stateDeletedManager.refreshDeletedEntries();
                    
                    //Refresh the entry as well.
                    final stateManager = context.read<EntriesState>();
                    await stateManager.refreshEntries();
                    
                    //Snackbar message
                    final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                    if (alertsEnabled && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
                      ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Center(
                            child: Text(
                              '${deletedEntry.title} Restored',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          backgroundColor: Colors.green[400],
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        )
                      );
                    }

                    Navigator.pop(context);
                  },
                ),

                //Delete Entry Permanently
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete Entry Permanently'),
                  onTap: () async {
                    
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Permanently Delete?'),
                        content: const Text('This action cannot be undone. Are you sure?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete')
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      await _dbHelper.deleteEntryPermanently(deletedEntry.deletedId!);
                      final stateDeletedManager = context.read<DeletedState>();
                      await stateDeletedManager.refreshDeletedEntries();
                      
                      //Snackbar message
                      final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                      if (alertsEnabled && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
                        ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              '${deletedEntry.title} permanently deleted',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.red[400],
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    }

                    Navigator.pop(context);
                  },
                ),

                //Share Entry
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share Entry'),
                  onTap: () async {
                    Navigator.pop(context);
                    _shareEntry(deletedEntry);
                  }
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  //Share Entry
  Future<String> generateShareableEntryText(DeletedEntry deletedEntry) async {
    final decryptedUsername = deletedEntry.username;
    final decryptedPassword = deletedEntry.password ?? '-';
    final decryptedNotes = deletedEntry.notes ?? '-';
    final url = deletedEntry.url ?? '-';

    return '''
${deletedEntry.title}

Title: ${deletedEntry.title}
Username: $decryptedUsername
Password: $decryptedPassword
URL: $url
Notes: $decryptedNotes

''';
  }

  void _shareEntry(DeletedEntry deletedEntry) async {
    final content = await generateShareableEntryText(deletedEntry);
    await Share.share(content, subject: deletedEntry.title);
  }

  // Helper function to build a consistent detail row
  Widget _buildDetailRow(BuildContext context, String label, String value, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              obscureText ? '********' : value,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  //Helper function to build a tappable URL row
  Widget _buildUrlRow(BuildContext context, String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: InkWell(
              child: Text(
                url,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  //color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrlInBrowser(BuildContext context, String? rawUrl) async {
    final alertsEnabled = context.read<AlertsProvider>().showAlerts;

    if (rawUrl == null || rawUrl.trim().isEmpty) {
      if (alertsEnabled && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Center(child: Text('🔗 The URL field is empty')),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(seconds: 2),
            ),
          );
      }
      return;
    }

    final formattedUrl = NormalizeUrl.urlFormatter(rawUrl);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Open Link in Browser?"),
        content: const Text("You are about to leave this app to open the link in your browser. Do you want to proceed?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Open')),
        ],
      ),
    );

    if (confirm == true && await canLaunchUrl(Uri.parse(formattedUrl))) {
      await launchUrl(Uri.parse(formattedUrl), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {

    final deletedEntriesProvider = Provider.of<DeletedState>(context);
    final sortProvider = Provider.of<SortProvider>(context);

    List <DeletedEntry> sortedDeletedEntries = [...deletedEntriesProvider.deletedEntries];

    if (sortProvider.sortMode == 'Title (A-Z)') {
      sortedDeletedEntries.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (sortProvider.sortMode == 'Username (A-Z)') {
      sortedDeletedEntries.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
    } else if (sortProvider.sortMode == 'Last Updated') {
      sortedDeletedEntries.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    } else {
      //Recently Added
      sortedDeletedEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return Scaffold(
      body: Column(
        children: [
          if (deletedEntriesProvider.isLoading && widget.isSearching)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: deletedEntriesProvider.deletedEntries.isEmpty
              ? Center(
                  child: Text(
                    "No Deleted Entries Available",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  itemCount: sortedDeletedEntries.length,
                  itemBuilder: (context, index) {

                    final deletedEntry = sortedDeletedEntries[index];

                    return Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.close, color: Colors.red),
                          title: Text(deletedEntry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(deletedEntry.username, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Text(
                            _formatDate(deletedEntry.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          onTap: () => _showDeletedEntryActions(context, deletedEntry),
                        ),
                        const Divider(height: 1, thickness: 0.5, color: Colors.grey),
                      ],
                    );
                  },
                ),
          ),
        ],
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/entry.dart';
import 'vault.dart';
import 'entries_state.dart';
import 'deleted_state.dart';
import 'view_entry.dart';
import 'edit_entry.dart';
import 'sort_provider.dart';
import 'alerts.dart';
import 'copy_to_clipboard.dart';
import 'normalize_url.dart';

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
  Timer? _searchDebounce;

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
        if (context.read<EntriesState>().searchText.isNotEmpty) {
          context.read<EntriesState>().fetchEntries();
        }
      } else {
        context.read<EntriesState>().searchEntries(query);
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
  void _navigateToViewEntry(Entry entry) async {
    final fullEntry = await Vault().getEntryById(entry.id!);
    if (fullEntry == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewEntry(entry: entry),
      ),
      // PageRouteBuilder(
      //   pageBuilder: (_, __, ___) => ViewEntry(entry: fullEntry),
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
      context.read<EntriesState>().fetchEntries();
    }
  }

  //To go Edit Entry
  void _navigateToEditEntry(Entry entry) async {
    final fullEntry = await Vault().getEntryById(entry.id!);
    if (fullEntry == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEntry(entry: entry),
      ),
    );

    if (result == true) {
      context.read<EntriesState>().fetchEntries();
    }
  }

  void _showEntryActions(BuildContext context, Entry entry) {
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
                      entry.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(context, 'Username:', entry.username),
                    _buildDetailRow(context, 'Password:', entry.password ?? '', obscureText: true),
                    if (entry.url != null && entry.url!.isNotEmpty)
                      _buildUrlRow(context, 'URL:', entry.url!),
                    if (entry.notes != null && entry.notes!.isNotEmpty)
                      _buildDetailRow(context, 'Notes:', entry.notes!),
                  ],
                ),
              ),
              const Divider(),

                //View Entry
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('View Entry'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToViewEntry(entry);
                  },
                ),

                //Copy Username
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy Username'),
                  onTap: () {
                    final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                    if (alertsEnabled && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
                      copyToClipboardWithFeedback(context, '👤', 'Username', entry.username);
                    } else {
                      Clipboard.setData(ClipboardData(text: entry.username));
                    }
                    Navigator.pop(context);
                  },
                ),

                //Copy Password
                if (entry.password != null && entry.password!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.copy),
                    title: const Text('Copy Password'),
                    onTap: () {
                      final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                      if (alertsEnabled && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
                        copyToClipboardWithFeedback(context, '🔑', 'Password', entry.password ?? '');
                      } else {
                        Clipboard.setData(ClipboardData(text: entry.password ?? ''));
                      }
                      Navigator.pop(context);
                    },
                  ),

                //Copy URL
                if (entry.url != null && entry.url!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.copy),
                    title: const Text('Copy URL'),
                    onTap: () {
                      final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                      if (alertsEnabled && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
                        copyToClipboardWithFeedback(context, '🔗', 'URL', entry.url ?? '');
                      } else {
                        Clipboard.setData(ClipboardData(text: entry.url ?? ''));
                      }
                      Navigator.pop(context);
                    },
                  ),

                // Open URL in Browser
                if (entry.url != null && entry.url!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.open_in_browser),
                    title: const Text('Open URL in Browser'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _openUrlInBrowser(context, entry.url);
                    },
                  ),

                //Edit Entry
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Entry'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToEditEntry(entry);
                  },
                ),

                //Delete Entry
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete Entry'),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Entry?'),
                        content: Text('${entry.title} will be moved to Deleted Entries page'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Proceed'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          await Vault().softDeleteEntry(entry.id!);
                          await context.read<EntriesState>().refreshEntries();
                          await context.read<DeletedState>().refreshDeletedEntries();
                          
                          //Snackbar message
                          final alertsEnabled = context.read<AlertsProvider>().showAlerts;
                          if (alertsEnabled && context.mounted && ModalRoute.of(context)?.isCurrent == true) {
                            ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Center(
                                  child: Text(
                                    '${entry.title} moved to Deleted Entries',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              backgroundColor: Colors.red[400], 
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 2),
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
                    _shareEntry(entry);
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
  Future<String> generateShareableEntryText(Entry entry) async {
    final decryptedUsername = entry.username;
    final decryptedPassword = entry.password ?? '-';
    final decryptedNotes = entry.notes ?? '-';
    final url = entry.url ?? '-';

    return '''
${entry.title}

Title: ${entry.title}
Username: $decryptedUsername
Password: $decryptedPassword
URL: $url
Notes: $decryptedNotes

''';
  }

  void _shareEntry(Entry entry) async {
    final content = await generateShareableEntryText(entry);
    await Share.share(content, subject: entry.title);
  }

  //Helper function to build a consistent detail row
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
    final entriesProvider = Provider.of<EntriesState>(context);
    final sortProvider = Provider.of<SortProvider>(context);

    List<Entry> sortedEntries = [...entriesProvider.entries];

    if (sortProvider.sortMode == 'Title (A-Z)') {
      sortedEntries.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (sortProvider.sortMode == 'Username (A-Z)') {
      sortedEntries.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
    } else if (sortProvider.sortMode == 'Last Updated') {
      sortedEntries.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    } else {
      sortedEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return Scaffold(
      body: Column(
        children: [
          if (entriesProvider.isLoading && widget.isSearching)
            const LinearProgressIndicator(minHeight: 2),

          Expanded(
            child: sortedEntries.isEmpty
                ? Center(
                    child: Text(
                      "No Entries Available",
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedEntries.length,
                    itemBuilder: (context, index) {

                      final entry = sortedEntries[index];

                      return Column(
                        children: [
                          ListTile(
                              leading: const Icon(Icons.key, color: Colors.amber),
                              title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(entry.username, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: Text(
                                _formatDate(entry.createdAt),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              onTap: () => _showEntryActions(context, entry),
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

  String _formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } catch (e) {
      return isoString;
    }
  }
}
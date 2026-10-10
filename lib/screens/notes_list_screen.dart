import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../services/database_helper.dart';
import '../services/theme_manager.dart';
import 'note_editor_screen.dart';

class NotesListScreen extends StatefulWidget {
  final ThemeManager themeManager;

  const NotesListScreen({super.key, required this.themeManager});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  List<Note> _notes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final notes = await DatabaseHelper.instance.getNotes(
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
    if (mounted) {
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadNotes();
  }

  Future<void> _openEditor([Note? note]) async {
    final updated = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (context) => NoteEditorScreen(initialNote: note),
      ),
    );
    if (updated == true || note == null) {
      await _loadNotes();
    }
  }

  Future<void> _togglePin(Note note) async {
    if (note.id == null) return;
    await DatabaseHelper.instance.togglePin(note.id!, !note.isPinned);
    await _loadNotes();
  }

  void _showNoteActions(Note note) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoActionSheet(
        title: Text(
          note.title.isNotEmpty ? note.title : 'Untitled Note',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        message: const Text('Select an action for this note'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(dialogContext);
              _openEditor(note);
            },
            child: const Text('Edit Note'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(dialogContext);
              _togglePin(note);
            },
            child: Text(note.isPinned ? 'Unpin Note' : 'Pin to Top'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (note.id != null) {
                await DatabaseHelper.instance.deleteNote(note.id!);
                await _loadNotes();
              }
            },
            child: const Text('Delete Note'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(dialogContext);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0 && now.day == dateTime.day) {
      return 'Today, ${DateFormat('h:mm a').format(dateTime)}';
    } else if (difference.inDays <= 1 && now.subtract(const Duration(days: 1)).day == dateTime.day) {
      return 'Yesterday, ${DateFormat('h:mm a').format(dateTime)}';
    } else if (now.year == dateTime.year) {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('ClearNote'),
                leading: Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_notes.length} ${_notes.length == 1 ? 'note' : 'notes'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    widget.themeManager.toggleTheme();
                  },
                  child: Icon(
                    isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_stars_fill,
                    size: 22,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF4F46E5),
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: 'Search notes...',
                    onChanged: _onSearchChanged,
                    onSuffixTap: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    style: TextStyle(
                      color: isDark ? CupertinoColors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),

              // Notes List or Empty State
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CupertinoActivityIndicator(radius: 14),
                  ),
                )
              else if (_notes.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _searchQuery.isNotEmpty
                                  ? CupertinoIcons.search
                                  : CupertinoIcons.doc_text,
                              size: 38,
                              color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _searchQuery.isNotEmpty ? 'No Matching Notes' : 'No Notes Yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? CupertinoColors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No notes matched "$_searchQuery". Try searching another phrase.'
                                : 'Capture thoughts, daily tasks, and ideas in clean plain text.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final note = _notes[index];
                        return _buildNoteCard(note, isDark, theme);
                      },
                      childCount: _notes.length,
                    ),
                  ),
                ),
            ],
          ),

          // Floating Cupertino Compose Button
          Positioned(
            right: 20,
            bottom: 28,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5))
                        .withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                borderRadius: BorderRadius.circular(30),
                onPressed: () => _openEditor(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.pencil_outline, size: 20, color: CupertinoColors.white),
                    SizedBox(width: 8),
                    Text(
                      'New Note',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note, bool isDark, CupertinoThemeData theme) {
    final previewContent = note.content.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F30) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: note.isPinned
              ? (isDark ? const Color(0xFF4F46E5) : const Color(0xFF818CF8)).withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          width: note.isPinned ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0x30000000)
                : const Color(0x0A000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(16),
        pressedOpacity: 0.7,
        borderRadius: BorderRadius.circular(16),
        onPressed: () => _openEditor(note),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note.title.isNotEmpty ? note.title : 'Untitled Note',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                      color: isDark ? CupertinoColors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (note.isPinned) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    CupertinoIcons.pin_fill,
                    size: 15,
                    color: CupertinoColors.activeOrange,
                  ),
                ],
                const SizedBox(width: 4),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _showNoteActions(note),
                  child: Icon(
                    CupertinoIcons.ellipsis,
                    size: 18,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            if (previewContent.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                previewContent,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  _formatTimestamp(note.updatedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
                const Spacer(),
                Text(
                  '${note.wordCount} words',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../services/database_helper.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? initialNote;

  const NoteEditorScreen({super.key, this.initialNote});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _contentFocusNode;

  int? _noteId;
  late DateTime _createdAt;
  late DateTime _updatedAt;
  late bool _isPinned;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _noteId = widget.initialNote?.id;
    _titleController = TextEditingController(text: widget.initialNote?.title ?? '');
    _contentController = TextEditingController(text: widget.initialNote?.content ?? '');
    _contentFocusNode = FocusNode();
    _createdAt = widget.initialNote?.createdAt ?? DateTime.now();
    _updatedAt = widget.initialNote?.updatedAt ?? DateTime.now();
    _isPinned = widget.initialNote?.isPinned ?? false;

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);

    // Auto focus content if title is already provided
    if (widget.initialNote == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Leave focus on title when creating new note
      });
    }
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    } else {
      // Trigger rebuild for word/character count updates
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // If both title and content are empty, do not create or delete empty draft
    if (title.isEmpty && content.isEmpty) {
      if (_noteId != null) {
        await DatabaseHelper.instance.deleteNote(_noteId!);
      }
      return;
    }

    if (_isSaving) return;
    _isSaving = true;

    final effectiveTitle = title.isEmpty ? 'Untitled Note' : title;
    final now = DateTime.now();

    final note = Note(
      id: _noteId,
      title: effectiveTitle,
      content: content,
      createdAt: _createdAt,
      updatedAt: now,
      isPinned: _isPinned,
    );

    if (_noteId == null) {
      final newId = await DatabaseHelper.instance.insertNote(note);
      _noteId = newId;
    } else {
      await DatabaseHelper.instance.updateNote(note);
    }

    _updatedAt = now;
    _hasChanges = false;
    _isSaving = false;
  }

  Future<void> _togglePin() async {
    setState(() {
      _isPinned = !_isPinned;
      _hasChanges = true;
    });
    if (_noteId != null) {
      await DatabaseHelper.instance.togglePin(_noteId!, _isPinned);
    }
  }

  void _confirmDelete() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoActionSheet(
        title: const Text('Delete Note'),
        message: const Text('Are you sure you want to permanently delete this note?'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(dialogContext); // Close sheet
              if (_noteId != null) {
                await DatabaseHelper.instance.deleteNote(_noteId!);
              }
              if (mounted) {
                Navigator.of(context).pop(true); // Return with delete flag
              }
            },
            child: const Text('Delete'),
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

  int get _wordCount {
    final text = _contentController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  int get _charCount => _contentController.text.length;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateString = DateFormat('MMMM d, yyyy • h:mm a').format(_updatedAt);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _saveNote();
        }
      },
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          previousPageTitle: 'Notes',
          middle: Text(
            widget.initialNote == null ? 'New Note' : 'Edit Note',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                onPressed: _togglePin,
                child: Icon(
                  _isPinned ? CupertinoIcons.pin_fill : CupertinoIcons.pin,
                  size: 22,
                  color: _isPinned ? CupertinoColors.activeOrange : theme.primaryColor,
                ),
              ),
              if (widget.initialNote != null)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: _confirmDelete,
                  child: const Icon(
                    CupertinoIcons.trash,
                    size: 22,
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              CupertinoButton(
                padding: const EdgeInsets.only(left: 8),
                onPressed: () async {
                  await _saveNote();
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plain Text Title Field
                CupertinoTextField(
                  controller: _titleController,
                  placeholder: 'Title',
                  placeholderStyle: TextStyle(
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: isDark ? CupertinoColors.white : const Color(0xFF0F172A),
                  ),
                  decoration: null,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    _contentFocusNode.requestFocus();
                  },
                ),
                const SizedBox(height: 10),

                // Note Metadata: Date and Word/Char Statistics
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.time,
                        size: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        dateString,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$_wordCount words  •  $_charCount chars',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Container(
                  height: 0.5,
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
                const SizedBox(height: 14),

                // Strictly Plain Text Content Field
                CupertinoTextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  placeholder: 'Start typing here...',
                  placeholderStyle: TextStyle(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                    fontSize: 17,
                    height: 1.5,
                  ),
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.5,
                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                  ),
                  decoration: null,
                  maxLines: null,
                  minLines: 15,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

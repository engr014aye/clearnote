import 'package:flutter_test/flutter_test.dart';
import 'package:clearnote/models/note.dart';

void main() {
  test('Note model serialization and calculations', () {
    final note = Note(
      id: 1,
      title: 'Meeting Notes',
      content: 'Discuss quarterly roadmap with the mobile team.',
      createdAt: DateTime(2026, 10, 11, 10, 0),
      updatedAt: DateTime(2026, 10, 11, 10, 30),
      isPinned: true,
    );

    expect(note.wordCount, 7);
    expect(note.characterCount, 47);
    expect(note.isPinned, true);

    final map = note.toMap();
    expect(map['title'], 'Meeting Notes');
    expect(map['is_pinned'], 1);

    final recreated = Note.fromMap(map);
    expect(recreated.title, note.title);
    expect(recreated.content, note.content);
    expect(recreated.isPinned, true);
  });
}

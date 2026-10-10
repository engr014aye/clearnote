import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'services/theme_manager.dart';
import 'screens/notes_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for seamless edge-to-edge feel
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: CupertinoColors.transparent,
      systemNavigationBarColor: CupertinoColors.transparent,
    ),
  );

  final themeManager = ThemeManager();

  runApp(ClearNoteApp(themeManager: themeManager));
}

class ClearNoteApp extends StatelessWidget {
  final ThemeManager themeManager;

  const ClearNoteApp({super.key, required this.themeManager});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, _) {
        return CupertinoApp(
          title: 'ClearNote',
          debugShowCheckedModeBanner: false,
          theme: themeManager.currentTheme,
          scrollBehavior: const _GlobalCupertinoScrollBehavior(),
          home: NotesListScreen(themeManager: themeManager),
        );
      },
    );
  }
}

class _GlobalCupertinoScrollBehavior extends CupertinoScrollBehavior {
  const _GlobalCupertinoScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

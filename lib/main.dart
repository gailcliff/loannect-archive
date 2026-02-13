
import 'package:flutter/material.dart';
import 'package:loannect/app_theme.dart' show theme;
import 'package:loannect/dat/AppCache.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/state/providers.dart' as state;
import 'package:provider/provider.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppCache.init();

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<StatefulWidget> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver{


  @override
  Widget build(BuildContext context) {
    final appRouter = router.router;

    return MultiProvider(
      providers: state.providers,
      child: MaterialApp.router(
        title: 'Loannect',
        theme: theme,
        routerDelegate: appRouter.routerDelegate,
        routeInformationProvider: appRouter.routeInformationProvider,
        routeInformationParser: appRouter.routeInformationParser,
      ),
    );
  }

  AppRouter get router => AppRouter();
}
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/main_shell_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const MainShellScreen(),
    ),
  ],
);

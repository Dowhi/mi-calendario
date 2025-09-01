import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/day_detail_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/year_summary_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/statistics_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/notification_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/shift_template_management_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/family_management_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/family_settings_screen.dart';
import 'package:calendario_familiar/features/calendar/presentation/screens/advanced_reports_screen.dart';
import 'package:calendario_familiar/features/auth/presentation/login_screen.dart';
import 'package:calendario_familiar/features/auth/presentation/email_signup_screen.dart';
import 'package:calendario_familiar/features/settings/presentation/screens/settings_screen.dart';
import 'package:calendario_familiar/main.dart';
import 'package:calendario_familiar/features/auth/logic/auth_controller.dart';

// Variable global para el navigatorKey
final navigatorKey = GlobalKey<NavigatorState>();

// Provider para el router que requiere acceso a Riverpod
final appRouterProvider = Provider<GoRouter>((ref) {
  // Verificar si una ruta es protegida (requiere autenticación)
  bool isProtectedRoute(String? path) {
    if (path == null) return false;
    
    final protectedRoutes = [
      '/',
      '/family-management',
      '/day-detail',
      '/year-summary',
      '/statistics',
      '/shift-templates',
      '/settings',
    ];
    
    return protectedRoutes.any((route) => path.startsWith(route));
  }

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: openedFromNotification ? '/notification-screen' : '/login',
    redirect: (context, state) async {
      print('🔄 Redirect llamado para: ${state.fullPath}');
      
      // Primero verificar si viene de notificación
      if (openedFromNotification && state.fullPath != '/notification-screen') {
        print('🔔 Redirigiendo a notificación');
        openedFromNotification = false;
        return '/notification-screen';
      }
      
      // Obtener el usuario actual del AuthController
      final currentUser = ref.read(authControllerProvider);
      print('🔐 Usuario actual: ${currentUser?.displayName ?? 'null'}');
      
      // Si no hay usuario autenticado y no estamos en una ruta de autenticación
      if (currentUser == null && 
          !(state.fullPath?.startsWith('/login') ?? false) && 
          !(state.fullPath?.startsWith('/email-signup') ?? false) &&
          state.fullPath != '/notification-screen') {
        print('🔐 No hay usuario autenticado, redirigiendo a login');
        return '/login';
      }
      
      // Si hay usuario autenticado y estamos en login, redirigir según tenga familia o no
      if (currentUser != null && state.fullPath == '/login') {
        print('🔐 Usuario autenticado en login, verificando familia...');
        // Verificar si el usuario tiene familia
        final hasFamily = await ref.read(authControllerProvider.notifier).currentUserHasFamily();
        if (hasFamily) {
          print('✅ Usuario tiene familia, redirigiendo al calendario');
          return '/'; // Retornar la ruta en lugar de navegar
        } else {
          print('⚠️ Usuario no tiene familia, redirigiendo a gestión familiar');
          return '/family-management'; // Retornar la ruta en lugar de navegar
        }
      }
      
      // Si hay usuario autenticado y estamos en email-signup, redirigir al calendario
      if (currentUser != null && state.fullPath == '/email-signup') {
        print('✅ Usuario ya autenticado, redirigiendo al calendario');
        return '/';
      }
      
      // Si hay usuario autenticado y estamos en una ruta protegida, verificar familia
      if (currentUser != null && isProtectedRoute(state.fullPath)) {
        print('🔐 Usuario autenticado en ruta protegida, verificando familia...');
        // Verificar si el usuario tiene familia para determinar la ruta
        final hasFamily = await ref.read(authControllerProvider.notifier).currentUserHasFamily();
        if (hasFamily) {
          print('✅ Usuario tiene familia, permitiendo acceso a ruta protegida');
          // No redirigir, permitir acceso
        } else {
          print('⚠️ Usuario no tiene familia, redirigiendo a gestión familiar');
          return '/family-management'; // Retornar la ruta en lugar de navegar
        }
      }
      
      print('✅ No hay redirección necesaria');
      return null; // No redirigir
    },
    routes: [
      // Ruta de login (pública)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Ruta de registro por email (pública)
      GoRoute(
        path: '/email-signup',
        builder: (context, state) => const EmailSignupScreen(),
      ),
      
      // Ruta de notificaciones (pública, para notificaciones push)
      GoRoute(
        path: '/notification-screen',
        builder: (context, state) {
          final Map<String, dynamic>? extraData = state.extra as Map<String, dynamic>?;
          final String eventText = extraData != null 
              ? extraData['eventText'] as String? ?? pendingEventText 
              : pendingEventText;
          final DateTime eventDate = extraData != null 
              ? extraData['eventDate'] as DateTime? ?? pendingEventDate 
              : pendingEventDate;
          return NotificationScreen(
            eventText: eventText,
            eventDate: eventDate,
          );
        },
      ),
      
      // Ruta principal del calendario (requiere autenticación)
      GoRoute(
        path: '/',
        builder: (context, state) => const CalendarScreen(),
      ),
      
      // Ruta de detalle del día (requiere autenticación)
      GoRoute(
        path: '/day-detail',
        builder: (context, state) {
          final extraData = state.extra as Map<String, dynamic>?;
          if (extraData == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Datos no proporcionados para DayDetailScreen')),
            );
          }
          
          final date = extraData['date'] as DateTime?;
          final existingText = extraData['existingText'] as String?;
          final existingEventId = extraData['existingEventId'] as String?;
          
          if (date == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Fecha no proporcionada para DayDetailScreen')),
            );
          }
          
          return DayDetailScreen(
            date: date,
            existingText: existingText,
            existingEventId: existingEventId,
          );
        },
      ),
      
      // Ruta del resumen anual (requiere autenticación)
      GoRoute(
        path: '/year-summary',
        builder: (context, state) {
          final year = state.extra as int? ?? DateTime.now().year;
          return YearSummaryScreen(year: year);
        },
      ),
      
      // Ruta de estadísticas (requiere autenticación)
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      
      // Ruta para la gestión de plantillas de turnos (requiere autenticación)
      GoRoute(
        path: '/shift-templates',
        builder: (context, state) => const ShiftTemplateManagementScreen(),
      ),
      
      // Ruta para la gestión familiar (requiere autenticación)
      GoRoute(
        path: '/family-management',
        builder: (context, state) => const FamilyManagementScreen(),
      ),
      
      // Ruta para la configuración de familia (requiere autenticación)
      GoRoute(
        path: '/family-settings',
        builder: (context, state) => const FamilySettingsScreen(),
      ),
      
      // Ruta para reportes avanzados (requiere autenticación)
      GoRoute(
        path: '/advanced-reports',
        builder: (context, state) => const AdvancedReportsScreen(),
      ),
      
      // Ruta para la pantalla de configuración (requiere autenticación)
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error 404',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Router legacy para compatibilidad (se usará temporalmente)
final appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: openedFromNotification ? '/notification-screen' : '/',
  redirect: (context, state) {
    if (openedFromNotification && state.fullPath != '/notification-screen') {
      openedFromNotification = false;
      return '/notification-screen';
    }
    return null;
  },
  routes: [
    // Ruta principal del calendario
    GoRoute(
      path: '/',
      builder: (context, state) => const CalendarScreen(),
    ),
    
    // Ruta de detalle del día
    GoRoute(
      path: '/day-detail',
      builder: (context, state) {
        final extraData = state.extra as Map<String, dynamic>?;
        if (extraData == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Datos no proporcionados para DayDetailScreen')),
          );
        }
        
        final date = extraData['date'] as DateTime?;
        final existingText = extraData['existingText'] as String?;
        final existingEventId = extraData['existingEventId'] as String?;
        
        if (date == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Fecha no proporcionada para DayDetailScreen')),
          );
        }
        
        return DayDetailScreen(
          date: date,
          existingText: existingText,
          existingEventId: existingEventId,
        );
      },
    ),
    
    // Ruta del resumen anual
    GoRoute(
      path: '/year-summary',
      builder: (context, state) {
        final year = state.extra as int? ?? DateTime.now().year;
        return YearSummaryScreen(year: year);
      },
    ),
    
    // Ruta de estadísticas
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsScreen(),
    ),
    // Nueva ruta para la gestión de plantillas de turnos
    GoRoute(
      path: '/shift-templates',
      builder: (context, state) => const ShiftTemplateManagementScreen(),
    ),
    // Nueva ruta para la gestión familiar
    GoRoute(
      path: '/family-management',
      builder: (context, state) => const FamilyManagementScreen(),
    ),
    // Nueva ruta para la configuración de familia
    GoRoute(
      path: '/family-settings',
      builder: (context, state) => const FamilySettingsScreen(),
    ),
    
    // Nueva ruta para reportes avanzados
    GoRoute(
      path: '/advanced-reports',
      builder: (context, state) => const AdvancedReportsScreen(),
    ),
    // Nueva ruta para el login
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    // Nueva ruta para el registro por email
    GoRoute(
      path: '/email-signup',
      builder: (context, state) => const EmailSignupScreen(),
    ),
    // Nueva ruta para la pantalla de configuración
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    // Nueva ruta para la pantalla de notificación de alarma
    GoRoute(
      path: '/notification-screen',
      builder: (context, state) {
        final Map<String, dynamic>? extraData = state.extra as Map<String, dynamic>?;
        final String eventText = extraData != null 
            ? extraData['eventText'] as String? ?? pendingEventText 
            : pendingEventText; // Usar global si no viene en extra
        final DateTime eventDate = extraData != null 
            ? extraData['eventDate'] as DateTime? ?? pendingEventDate 
            : pendingEventDate; // Usar global si no viene en extra
        return NotificationScreen(
          eventText: eventText,
          eventDate: eventDate,
        );
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error 404',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Página no encontrada',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Volver al inicio'),
          ),
        ],
      ),
    ),
  ),
);


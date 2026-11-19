import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/doctor/chat_screens.dart';
import '../features/doctor/clinic_screen.dart';
import '../features/doctor/dashboard_screen.dart';
import '../features/doctor/doctor_shell.dart';
import '../features/doctor/followups_screen.dart';
import '../features/doctor/patient_detail_screen.dart';
import '../features/doctor/patients_screen.dart';
import '../features/doctor/prescribe_screen.dart';
import '../features/parent/add_child_screen.dart';
import '../features/parent/book_appointment_screen.dart';
import '../features/parent/home_screen.dart';
import '../features/parent/join_clinic_screen.dart';
import '../features/parent/parent_shell.dart';
import '../features/parent/profile_screen.dart';
import '../features/parent/thin_screens.dart';
import '../features/parent/visits_screen.dart';
import '../features/shared/prescription_screen.dart';
import '../models/models.dart';
import '../providers.dart';

/// Keeps GoRouter in sync with auth + profile state.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen<String?>(userIdProvider, (_, __) => notifyListeners());
    _ref.listen<AsyncValue<Profile?>>(profileProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(GoRouterState state) {
    final loc = state.matchedLocation;
    final uid = _ref.read(userIdProvider);
    final isAuthRoute = loc == '/login' || loc == '/otp';

    if (uid == null) return isAuthRoute ? null : '/login';

    final profile = _ref.read(profileProvider);
    if (profile.isLoading || profile.hasError) return loc == '/splash' ? null : '/splash';

    final p = profile.valueOrNull;
    if (p == null) return loc == '/onboarding' ? null : '/onboarding';

    final home = p.role == UserRole.doctor ? '/doctor/dashboard' : '/parent/home';
    if (isAuthRoute || loc == '/onboarding' || loc == '/splash' || loc == '/') return home;

    if (p.role == UserRole.parent && loc.startsWith('/doctor')) return home;
    if (p.role == UserRole.doctor && loc.startsWith('/parent')) return home;
    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) => refresh.redirect(state),
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) => OtpScreen(phone: (state.extra as String?) ?? ''),
      ),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

      // ---------------- Parent ----------------
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ParentShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/parent/home', builder: (_, __) => const ParentHomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/parent/vaccines', builder: (_, __) => const ParentVaccinesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/parent/growth', builder: (_, __) => const ParentGrowthScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/parent/visits', builder: (_, __) => const ParentVisitsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/parent/chat', builder: (_, __) => const ParentChatScreen()),
          ]),
        ],
      ),
      GoRoute(path: '/parent/add-child', builder: (_, __) => const AddChildScreen()),
      GoRoute(path: '/parent/join-clinic', builder: (_, __) => const JoinClinicScreen()),
      GoRoute(path: '/parent/book', builder: (_, __) => const BookAppointmentScreen()),
      GoRoute(path: '/parent/records', builder: (_, __) => const ParentRecordsScreen()),
      GoRoute(path: '/parent/profile', builder: (_, __) => const ProfileScreen()),

      // ---------------- Doctor ----------------
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => DoctorShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/doctor/dashboard', builder: (_, __) => const DoctorDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/doctor/patients', builder: (_, __) => const PatientsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/doctor/followups', builder: (_, __) => const FollowUpsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/doctor/chat', builder: (_, __) => const ChatInboxScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/doctor/clinic', builder: (_, __) => const ClinicScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/doctor/patient/:childId',
        builder: (_, state) => PatientDetailScreen(
          childId: state.pathParameters['childId']!,
          appointmentId: state.uri.queryParameters['appt'],
        ),
        routes: [
          GoRoute(
            path: 'prescribe',
            builder: (_, state) => PrescribeScreen(
              childId: state.pathParameters['childId']!,
              appointmentId: state.uri.queryParameters['appt'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/doctor/chat/:childId',
        builder: (_, state) => DoctorChatScreen(childId: state.pathParameters['childId']!),
      ),

      // ---------------- Shared ----------------
      GoRoute(
        path: '/prescription/:id',
        builder: (_, state) => PrescriptionScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});

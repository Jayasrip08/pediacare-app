import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/choose_role_screen.dart';
import '../features/auth/doctor_register_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/onboarding_flow_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/doctor/appointments_screen.dart';
import '../features/doctor/chat_screens.dart';
import '../features/doctor/clinic_screen.dart';
import '../features/doctor/dashboard_screen.dart';
import '../features/doctor/doctor_shell.dart';
import '../features/doctor/followups_screen.dart';
import '../features/doctor/lab_referral_screen.dart';
import '../features/doctor/opd_analytics_screen.dart';
import '../features/doctor/opd_queue_screen.dart';
import '../features/doctor/patient_detail_screen.dart';
import '../features/doctor/patients_screen.dart';
import '../features/doctor/pediatric_calc_screen.dart';
import '../features/doctor/prescribe_screen.dart';
import '../features/doctor/vaccine_inventory_screen.dart';
import '../features/parent/add_child_screen.dart';
import '../features/parent/appointment_confirmed_screen.dart';
import '../features/parent/appointments_screen.dart';
import '../features/parent/book_appointment_screen.dart';
import '../features/parent/emergency_screen.dart';
import '../features/parent/home_screen.dart';
import '../features/parent/join_clinic_screen.dart';
import '../features/parent/med_tracker_screen.dart';
import '../features/parent/milestones_screen.dart';
import '../features/parent/parent_shell.dart';
import '../features/parent/profile_screen.dart';
import '../features/parent/select_doctor_screen.dart';
import '../features/parent/symptom_checker_screen.dart';
import '../features/parent/thin_screens.dart';
import '../features/parent/vaccine_tracker_screen.dart';
import '../features/parent/visits_screen.dart';
import '../features/shared/prescription_screen.dart';
import '../models/models.dart';
import '../providers.dart';

/// Keeps GoRouter in sync with auth, role, and profile state.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen<UserRole?>(currentUserRoleProvider, (_, __) => notifyListeners());
    _ref.listen<String?>(userIdProvider, (_, __) => notifyListeners());
    _ref.listen<AsyncValue<Profile?>>(profileProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(GoRouterState state) {
    final loc = state.matchedLocation;
    final userRole = _ref.read(currentUserRoleProvider);
    final uid = _ref.read(userIdProvider);

    final isPublicRoute = loc == '/splash' ||
        loc == '/onboarding' ||
        loc == '/choose-role' ||
        loc == '/login' ||
        loc == '/register' ||
        loc == '/doctor/register' ||
        loc == '/otp';

    // 0. Public routes are always accessible for auth & registration flows
    if (isPublicRoute) {
      return null;
    }

    // 1. Strict RBAC: Doctor Role Enforcement
    if (userRole == UserRole.doctor) {
      // Doctor is strictly forbidden from accessing Parent portals
      if (loc.startsWith('/parent')) {
        return '/doctor/dashboard';
      }
      if (loc == '/') {
        return '/doctor/dashboard';
      }
      return null;
    }

    // 2. Strict RBAC: Parent Role Enforcement
    if (userRole == UserRole.parent) {
      // Parent is strictly forbidden from accessing Doctor clinical portals
      if (loc.startsWith('/doctor')) {
        return '/parent/home';
      }
      if (loc == '/') {
        return '/parent/home';
      }
      return null;
    }

    // 3. Remote Supabase Profile fallback if set
    if (uid != null) {
      final profile = _ref.read(profileProvider);
      final p = profile.valueOrNull;
      if (p != null) {
        if (p.role == UserRole.doctor && loc.startsWith('/parent')) {
          return '/doctor/dashboard';
        }
        if (p.role == UserRole.parent && loc.startsWith('/doctor')) {
          return '/parent/home';
        }
      }
    }

    if (uid == null && !isPublicRoute && userRole == null) {
      // Allow unrestricted direct preview if browsing without explicit auth
      if (loc.startsWith('/parent') || loc.startsWith('/doctor')) return null;
      return '/splash';
    }

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
      // 1. Splash Screen
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),

      // 2, 3, 4. Onboarding Flow (3 slides)
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingFlowScreen()),

      // 5. Choose Your Role
      GoRoute(path: '/choose-role', builder: (_, __) => const ChooseRoleScreen()),

      // 6. Role-specific Login Screen (Parent & Doctor)
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginScreen(
          role: state.uri.queryParameters['role'] ?? 'parent',
        ),
      ),

      // 7. Create Parent Account
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Phone OTP
      GoRoute(
        path: '/otp',
        builder: (_, state) => OtpScreen(phone: (state.extra as String?) ?? ''),
      ),

      // 8. Parent Home Dashboard
      GoRoute(path: '/parent/home', builder: (_, __) => const ParentHomeScreen()),

      // 9. Add Child
      GoRoute(path: '/parent/add-child', builder: (_, __) => const AddChildScreen()),

      // 10. Book Appointment - Select Department
      GoRoute(path: '/parent/book', builder: (_, __) => const BookAppointmentScreen()),

      // 11. Select Doctor
      GoRoute(
        path: '/parent/select-doctor',
        builder: (_, state) => SelectDoctorScreen(
          department: state.uri.queryParameters['dept'] ?? 'Pediatrics',
        ),
      ),

      // 12. Appointment Confirmed
      GoRoute(
        path: '/parent/appointment-confirmed',
        builder: (_, state) => AppointmentConfirmedScreen(
          doctorName: state.uri.queryParameters['doc'] ?? 'Pediatrician',
          specialty: state.uri.queryParameters['spec'] ?? 'Pediatrician',
        ),
      ),

      // 13. Doctor Dashboard
      GoRoute(path: '/doctor/dashboard', builder: (_, __) => const DoctorDashboardScreen()),

      // 14. Patient Details
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

      // Parent Additional Screens (Vaccines, Growth, Visits, Records)
      GoRoute(path: '/parent/appointments', builder: (_, __) => const ParentAppointmentsScreen()),
      GoRoute(path: '/parent/vaccines', builder: (_, __) => const VaccineTrackerScreen()),
      GoRoute(path: '/parent/growth', builder: (_, __) => const ParentGrowthScreen()),
      GoRoute(path: '/parent/visits', builder: (_, __) => const ParentVisitsScreen()),
      GoRoute(path: '/parent/records', builder: (_, __) => const ParentRecordsScreen()),
      GoRoute(path: '/parent/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/parent/join-clinic', builder: (_, __) => const JoinClinicScreen()),
      GoRoute(path: '/parent/med-tracker', builder: (_, __) => const MedTrackerScreen()),
      GoRoute(path: '/parent/symptom-checker', builder: (_, __) => const SymptomCheckerScreen()),
      GoRoute(path: '/parent/milestones', builder: (_, __) => const MilestonesScreen()),
      GoRoute(path: '/parent/emergency', builder: (_, __) => const EmergencyScreen()),

      // Doctor Additional Screens
      GoRoute(path: '/doctor/register', builder: (_, __) => const DoctorRegisterScreen()),
      GoRoute(path: '/doctor/appointments', builder: (_, __) => const DoctorAppointmentsScreen()),
      GoRoute(path: '/doctor/patients', builder: (_, __) => const PatientsScreen()),
      GoRoute(path: '/doctor/followups', builder: (_, __) => const FollowUpsScreen()),
      GoRoute(path: '/doctor/chat', builder: (_, __) => const ChatInboxScreen()),
      GoRoute(path: '/doctor/clinic', builder: (_, __) => const ClinicScreen()),
      GoRoute(path: '/doctor/queue', builder: (_, __) => const OpdQueueScreen()),
      GoRoute(path: '/doctor/calc', builder: (_, __) => const PediatricCalcScreen()),
      GoRoute(path: '/doctor/inventory', builder: (_, __) => const VaccineInventoryScreen()),
      GoRoute(path: '/doctor/analytics', builder: (_, __) => const OpdAnalyticsScreen()),
      GoRoute(path: '/doctor/orders', builder: (_, __) => const LabReferralScreen()),
      GoRoute(
        path: '/doctor/chat/:childId',
        builder: (_, state) => DoctorChatScreen(childId: state.pathParameters['childId']!),
      ),

      // Shared
      GoRoute(
        path: '/prescription/:id',
        builder: (_, state) => PrescriptionScreen(id: state.pathParameters['id']!),
      ),
    ],
  );
});

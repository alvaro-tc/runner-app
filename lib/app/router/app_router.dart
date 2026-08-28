import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/app/router/guards.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/features/admin/presentation/pages/admin_home_page.dart';
import 'package:camrun/features/admin/presentation/pages/admin_marathon_edit_page.dart';
import 'package:camrun/features/admin/presentation/pages/admin_marathons_page.dart';
import 'package:camrun/features/admin/presentation/pages/admin_users_page.dart';
import 'package:camrun/features/auth/presentation/pages/change_password_page.dart';
import 'package:camrun/features/auth/presentation/pages/delete_account_page.dart';
import 'package:camrun/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:camrun/features/auth/presentation/pages/sign_in_page.dart';
import 'package:camrun/features/auth/presentation/pages/sign_up_page.dart';
import 'package:camrun/features/auth/presentation/pages/welcome_page.dart';
import 'package:camrun/features/auth/presentation/providers/auth_provider.dart';
import 'package:camrun/features/home/presentation/pages/home_page.dart';
import 'package:camrun/features/home/presentation/pages/marathon_detail_page.dart';
import 'package:camrun/features/home/presentation/pages/marathon_register_page.dart';
import 'package:camrun/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:camrun/features/profile/presentation/pages/appearance_page.dart';
import 'package:camrun/features/profile/presentation/pages/language_page.dart';
import 'package:camrun/features/profile/presentation/pages/profile_edit_page.dart';
import 'package:camrun/features/profile/presentation/pages/profile_page.dart';
import 'package:camrun/features/profile/presentation/pages/profile_settings_page.dart';
import 'package:camrun/features/races/presentation/pages/race_detail_page.dart';
import 'package:camrun/features/races/presentation/pages/race_start_page.dart';
import 'package:camrun/features/races/presentation/pages/races_page.dart';
import 'package:camrun/features/races/presentation/widgets/marathon_start_watcher.dart';
import 'package:camrun/features/train/presentation/pages/run_session_page.dart';
import 'package:camrun/features/train/presentation/pages/run_summary_page.dart';
import 'package:camrun/features/train/presentation/pages/train_page.dart';
import 'package:camrun/features/train/presentation/pages/train_setup_page.dart';
import 'package:camrun/shared/widgets/organisms/app_shell.dart';
import 'package:camrun/shared/widgets/organisms/showcase_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  // GoRouter is built once; this notifier is what tells it to re-evaluate the
  // redirect when the session or the onboarding flag changes.
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authProvider, (_, _) => refresh.value++)
    ..listen(
      settingsProvider.select((s) => s.onboardingSeen),
      (_, _) => refresh.value++,
    )
    ..onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.home,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) => appGuard(ref, state),
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: Routes.signUp,
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      // Ajustes, apariencia, idioma y edicion del perfil: **una sola copia**.
      // Son identicas para el corredor y para el admin, y viven fuera de los
      // dos shells porque duplicarlas dentro de cada uno significa arreglar
      // cada cambio dos veces.
      GoRoute(
        path: Routes.profileEdit,
        builder: (context, state) => const ProfileEditPage(),
      ),
      GoRoute(
        path: Routes.profileSettings,
        builder: (context, state) => const ProfileSettingsPage(),
      ),
      GoRoute(
        path: Routes.profileAppearance,
        builder: (context, state) => const AppearancePage(),
      ),
      GoRoute(
        path: Routes.profileLanguage,
        builder: (context, state) => const LanguagePage(),
      ),
      GoRoute(
        path: Routes.profileDeleteAccount,
        builder: (context, state) => const DeleteAccountPage(),
      ),
      if (kDebugMode)
        GoRoute(
          path: Routes.showcase,
          builder: (context, state) => const ShowcasePage(),
        ),
      // El panel: su propio arbol, su propia barra. Comparte armazon con el de
      // corredor pero no ramas —un admin no tiene plan de entrenamiento— y
      // meterlo como quinta pestana del otro obligaria a esconderla a mano en
      // cada pantalla.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            AppShell(shell: shell, admin: true),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.admin,
                builder: (context, state) => const AdminHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminMarathons,
                builder: (context, state) => const AdminMarathonsPage(),
                routes: [
                  // `new` antes que `:id`: si no, go_router resuelve "new"
                  // como un id y el alta abre la edicion de nada.
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) => const AdminMarathonEditPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) => AdminMarathonEditPage(
                      marathonId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminUsers,
                builder: (context, state) => const AdminUsersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminProfile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        // El vigia envuelve la app del corredor entera: la largada puede pillar
        // a alguien en cualquier pestana y el aviso tiene que llegarle igual.
        builder: (context, state, shell) =>
            MarathonStartWatcher(child: AppShell(shell: shell)),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomePage(),
                routes: [
                  GoRoute(
                    path: 'marathon/:id',
                    builder: (context, state) => MarathonDetailPage(
                      marathonId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'register',
                        builder: (context, state) => MarathonRegisterPage(
                          marathonId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.train,
                builder: (context, state) => const TrainPage(),
                routes: [
                  GoRoute(
                    path: 'setup',
                    builder: (context, state) => TrainSetupPage(
                      sessionId: state.uri.queryParameters['session'],
                    ),
                  ),
                  GoRoute(
                    path: 'session',
                    // Full screen: sits on the root navigator so the bottom
                    // bar is not visible while recording.
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) => const RunSessionPage(),
                  ),
                  GoRoute(
                    path: 'summary/:id',
                    builder: (context, state) =>
                        RunSummaryPage(runId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'history/:id',
                    builder: (context, state) => RunSummaryPage(
                      runId: state.pathParameters['id']!,
                      readOnly: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.races,
                builder: (context, state) => const RacesPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        RaceDetailPage(entryId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'start',
                        builder: (context, state) => RaceStartPage(
                          registrationId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

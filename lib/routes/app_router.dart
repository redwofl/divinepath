import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../utils/helpers.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/main_nav_screen.dart';
import '../screens/mantra/mantra_counter_screen.dart';
import '../screens/stories/stories_list_screen.dart';
import '../screens/stories/story_detail_screen.dart';
import '../screens/gita/gita_chapters_screen.dart';
import '../screens/gita/gita_verses_screen.dart';
import '../screens/gita/saved_verses_screen.dart';
import '../screens/gita/verse_detail_screen.dart';
import '../screens/gita/verse_search_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/game/bubble_game_screen.dart';
import '../screens/meditation/meditation_screen.dart';
import '../screens/meditation/meditation_timer_screen.dart';
import '../screens/challenges/challenges_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/community/community_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/admin/admin_panel_screen.dart';
import '../screens/premium/premium_screen.dart';

class AppRouter {
  final UserProvider userProvider;

  late final GoRouter router;

  AppRouter({required this.userProvider}) {
    router = GoRouter(
      navigatorKey: Helpers.navigatorKey,
      initialLocation: '/home',
      redirect: (context, state) {
        // First launch: send the user through onboarding before Home.
        if (!userProvider.hasCompletedOnboarding) {
          if (state.matchedLocation != '/onboarding') {
            return '/onboarding';
          }
        } else {
          // Returning user: never show onboarding again.
          if (state.matchedLocation == '/onboarding') {
            return '/home';
          }
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/premium',
          builder: (context, state) => const PremiumScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainNavScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/mantra',
                  builder: (context, state) => const MantraCounterScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/game',
                  builder: (context, state) => const BubbleGameScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/stories',
                  builder: (context, state) => const StoriesListScreen(),
                  routes: [
                    GoRoute(
                      path: ':storyId',
                      builder: (context, state) => StoryDetailScreen(
                        storyId: state.pathParameters['storyId'] ?? '',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/gita',
                  builder: (context, state) => const GitaChaptersScreen(),
                  routes: [
                    GoRoute(
                      path: ':chapterNumber',
                      builder: (context, state) => GitaVersesScreen(
                        chapterNumber: int.tryParse(state.pathParameters['chapterNumber'] ?? '1') ?? 1,
                      ),
                      routes: [
                        GoRoute(
                          path: ':verseNumber',
                          builder: (context, state) => VerseDetailScreen(
                            chapterNumber: int.tryParse(state.pathParameters['chapterNumber'] ?? '1') ?? 1,
                            verseNumber: int.tryParse(state.pathParameters['verseNumber'] ?? '1') ?? 1,
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
                  path: '/chat',
                  builder: (context, state) => const ChatScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/meditation',
          builder: (context, state) => const MeditationScreen(),
          routes: [
            GoRoute(
              path: 'timer/:type/:duration',
              builder: (context, state) => MeditationTimerScreen(
                type: state.pathParameters['type'] ?? 'focus',
                durationMinutes: int.tryParse(state.pathParameters['duration'] ?? '5') ?? 5,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/challenges',
          builder: (context, state) => const ChallengesScreen(),
        ),
        GoRoute(
          path: '/saved-verses',
          builder: (context, state) => const SavedVersesScreen(),
        ),
        GoRoute(
          path: '/verse-search',
          builder: (context, state) => const VerseSearchScreen(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/community',
          builder: (context, state) => const CommunityScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminPanelScreen(),
        ),
      ],
    );
  }
}

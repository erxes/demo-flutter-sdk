import 'dart:async';

import 'package:erxes_flutter_sdk/erxes_flutter_sdk.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// Mirrors the demo's `UserProfile` type.
class UserProfile {
  const UserProfile({required this.name, required this.email});

  final String name;
  final String email;
}

// Public test credentials from the erxes-ios-sdk example app:
// https://github.com/erxes/erxes-ios-sdk/tree/main/Example
const String kIntegrationId = '9S6seo9wawN6cou8v';
const String kEndpoint = 'https://officenext.erxes.io';

// The signed-in user. Forwarded to the messenger as `user` and to the Profile
// screen when the avatar action is tapped.
const UserProfile kCurrentUser = UserProfile(
  name: 'Munkh-orgil',
  email: 'monkhorgilbayarbaatar@gmail.com',
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Erxes SDK Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(),
    );
  }
}

/// Hosts the native chat modal — it has no UI of its own.
///
/// Chat mode opens full-screen and auto-opens once connected. The screen
/// renders nothing — the messenger UI is presented natively over the app.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<String>? _actionSub;

  @override
  void initState() {
    super.initState();

    // The messenger delivers a tapped action's id here. The `profile` action
    // navigates to the Profile screen, mirroring the demo's `visible={isFocused}`
    // behaviour: push Profile *underneath* the still-presented native chat (so no
    // blank Home frame flashes), then dismiss the chat to reveal it, and
    // re-present the chat once we return to Home.
    _actionSub = ErxesMessenger.onAction.listen((id) async {
      if (id != 'profile' || !mounted) return;

      final navigator = Navigator.of(context);
      final popped = navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const ProfileScreen(user: kCurrentUser),
        ),
      );
      await ErxesMessenger.hideMessenger();
      await popped;
      if (mounted) await ErxesMessenger.showMessenger();
    });

    _configureMessenger();
  }

  Future<void> _configureMessenger() async {
    await ErxesMessenger.configure(
      integrationId: kIntegrationId,
      endpoint: kEndpoint,
      displayMode: ErxesDisplayMode.chat,
      user: kCurrentUser.toErxesUser(),
      homeActions: const [
        ErxesAction(
          id: 'profile',
          title: 'Profile',
          // iOS uses an SF Symbol; Android resolves a Compose Material icon by
          // name (needs material-icons-extended for the full set).
          iosIcon: 'person.crop.circle',
          androidIcon: 'AccountCircle',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _actionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The messenger is presented natively over the app; nothing to draw here.
    return const Scaffold(body: SizedBox.shrink());
  }
}

extension on UserProfile {
  ErxesUser toErxesUser() => ErxesUser(name: name, email: email);
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user});

  final UserProfile user;

  Future<void> _handleClearCache(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ErxesMessenger.clearUser();
      messenger.showSnackBar(const SnackBar(content: Text('Cache cleared')));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to clear cache: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = user.name.isEmpty ? '' : user.name[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF3F78D9),
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.email,
              style: const TextStyle(fontSize: 15, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD93F3F),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
              ),
              onPressed: () => _handleClearCache(context),
              child: const Text('Clear cache'),
            ),
          ],
        ),
      ),
    );
  }
}

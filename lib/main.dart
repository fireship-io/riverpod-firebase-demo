import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// We create a "provider", which will store a value (here "Hello world").
// By using a provider, this allows us to mock/override the value exposed.
final helloWorldProvider = Provider((_) => 'Hello world');

final userProvider =
    Provider<User?>((ref) => FirebaseAuth.instance.currentUser);

final userProvider2 =
    StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    // For widgets to be able to read providers, we need to wrap the entire
    // application in a "ProviderScope" widget.
    // This is where the state of our providers will be stored.
    ProviderScope(
      child: MyApp(),
    ),
  );
}

// Note: MyApp is a HookConsumerWidget, from flutter_hooks.
class MyApp extends ConsumerWidget {
  final Future<FirebaseApp> _init = Firebase.initializeApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // To read our provider, we can use the hook "ref.watch(".
    // This is only possible because MyApp is a HookConsumerWidget.
    final String value = ref.watch(helloWorldProvider);

    final user = ref.watch(userProvider2);

    return user.when(
      data: (user) {
        return MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('Example')),
            body: Center(
              child: Text(user?.uid ?? 'not signed in'),
            ),
            floatingActionButton: FloatingActionButton(
              child: user != null ? Icon(Icons.outbond) : Icon(Icons.person),
              onPressed: () {
                if (user != null) {
                  FirebaseAuth.instance.signOut();
                } else {
                  FirebaseAuth.instance.signInAnonymously();
                }
              },
            ),
          ),
        );
      },
      error: (e, s) => Text('error'),
      loading: () => Text('loading'),
    );
  }
}

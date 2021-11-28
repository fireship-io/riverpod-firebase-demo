import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final helloWorldProvider = Provider((_) => 'Hello world');

final userProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String helloWorld = ref.watch(helloWorldProvider);

    final user = ref.watch(userProvider);

    return user.when(
      data: (user) {
        return MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text(helloWorld)),
            body: Column(
              children: [Text(user?.uid ?? 'not signed in'), AccountDetails()],
            ),
            floatingActionButton: FloatingActionButton(
              child: user != null ? Icon(Icons.outbond) : Icon(Icons.person),
              onPressed: () async {
                if (user != null) {
                  FirebaseAuth.instance.signOut();
                } else {
                  var credential =
                      await FirebaseAuth.instance.signInAnonymously();
                  var ref = FirebaseFirestore.instance
                      .collection('accounts')
                      .doc(credential.user?.uid);
                  ref.set({'hello': 'my account!!!'});
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

// Join provider Streams
final dataProvider = StreamProvider<Map?>(
  (ref) {
    final userStream = ref.watch(userProvider);

    var user = userStream.value; //.asData?.value;

    if (user != null) {
      var docRef =
          FirebaseFirestore.instance.collection('accounts').doc(user.uid);
      return docRef.snapshots().map((doc) => doc.data());
    } else {
      return Stream.empty();
    }
  },
);

// Listen to data in Firestore
class AccountDetails extends ConsumerWidget {
  @override
  Widget build(context, ref) {
    final data = ref.watch(dataProvider);

    return data.when(
      data: (account) {
        return Text(account?['hello'] ?? 'empty');
      },
      error: (e, s) => Text('error'),
      loading: () => Text('waiting for data...'),
    );
  }
}

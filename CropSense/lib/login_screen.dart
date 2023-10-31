import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'chat_screen.dart'; // Make sure to import the ChatScreen

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthenticationProvider(FirebaseAuth.instance),
    child: MaterialApp(
      home: Consumer<AuthenticationProvider>(
        builder: (context, authProvider, _) {
          return StreamProvider<User?>.value(
            initialData: authProvider.firebaseAuth.currentUser,
            value: authProvider.authState,
            child: AuthenticationWrapper(),
        );
      },
      ),
    ),
    );
  }
}

class AuthenticationProvider with ChangeNotifier {
  final FirebaseAuth firebaseAuth;

  AuthenticationProvider(this.firebaseAuth);

  Stream<User?> get authState => firebaseAuth.authStateChanges();

  Future<void> signIn({required String email, required String password}) async {
    try {
      await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
    } catch (e) {
      print(e); // Handle the exception properly in a production app
    }
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
    notifyListeners();
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser != null) {
      return ChatScreen(); // If the user is logged in, navigate to ChatScreen
    }
    return LoginScreen(); // If the user is not logged in, stay on LoginScreen
  }
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),  // Space at the top
            Image.asset(
                "assets/images/cropsense_logo.png",
                fit: BoxFit.fitWidth,
                width: 240,
                height: 240
              ),
              SizedBox(height: 40),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await authProvider.signIn(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login Successful!')),
                    );
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatScreen()));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login Failed: $e')),
                    );
                  }
                },
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

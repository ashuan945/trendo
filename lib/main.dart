import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfig.dart';
import 'auth/auth_wrapper.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'widget/draggable_chatbot.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  if (!Amplify.isConfigured) {
    final auth = AmplifyAuthCognito();
    await Amplify.addPlugin(auth);

    try {
      await Amplify.configure(amplifyconfig);
      print("Amplify configured successfully");
    } catch (e) {
      print("Error configuring Amplify: $e");
    }
  }

  runApp(const TrendoApp());
}

class TrendoApp extends StatelessWidget {
  const TrendoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trendo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

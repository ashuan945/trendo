import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../homepage.dart';
import 'email_confirmation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false; // Start with sign in

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await _signUpUser();
      } else {
        await _signInUser();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpUser() async {
    try {
      final result = await Amplify.Auth.signUp(
        username: _emailController.text.trim(),
        password: _passwordController.text,
        options: SignUpOptions(
          userAttributes: {
            CognitoUserAttributeKey.email: _emailController.text.trim(),
          },
        ),
      );

      if (result.isSignUpComplete) {
        // Sign up completed, user can sign in
        _showSuccess("Sign up successful! You can now sign in.");
        setState(() => _isSignUp = false);
      } else {
        // Need email confirmation
        _navigateToConfirmation();
      }
    } on AuthException catch (e) {
      _showError("Sign up failed: ${e.message}");
    }
  }

  Future<void> _signInUser() async {
    try {
      final result = await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result.isSignedIn) {
        print("Login successful!");
        _navigateToHome();
      } else {
        _showError("Sign in incomplete. Please try again.");
      }
    } on AuthException catch (e) {
      if (e.message.contains('not confirmed')) {
        _showError("Please confirm your email first");
        _navigateToConfirmation();
      } else {
        _showError("Sign in failed: ${e.message}");
      }
    }
  }

  void _navigateToConfirmation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfirmationPage(
          email: _emailController.text.trim(),
          onConfirmed: () {
            Navigator.of(context).pop();
            setState(() => _isSignUp = false);
            _showSuccess("Email confirmed! You can now sign in.");
          },
        ),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top flexible spacer - shrinks when keyboard appears
                Flexible(
                  flex: isKeyboardOpen ? 1 : 2,
                  child: Container(),
                ),
                
                // Logo - smaller when keyboard is open
                Container(
                  height: isKeyboardOpen ? 50 : 80,
                  width: isKeyboardOpen ? 50 : 80,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/icon/logo.jpg'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                // Reduced spacing when keyboard is open
                SizedBox(height: isKeyboardOpen ? 8 : 16),
                
                Text(
                  'Trendo',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: isKeyboardOpen ? 16 : 32),

                // Welcome message - hide when keyboard is open on small screens
                if (!isKeyboardOpen || MediaQuery.of(context).size.height > 600)
                  Column(
                    children: [
                      Text(
                        _isSignUp ? 'Welcome! Create your account' : 'Welcome back!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isKeyboardOpen ? 16 : 24),
                    ],
                  ),

                // Email field
                TextFormField(
                  controller: _emailController,
                  cursorColor: Colors.blue[600],
                  decoration: InputDecoration(
                    labelText: 'Email',
                    floatingLabelStyle: TextStyle(
                      color: Colors.blue[600], // Focused label color (blue)
                    ),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[600]!, width: 2.0),
                    ),
                    prefixIcon: const Icon(Icons.email),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  cursorColor: Colors.blue[600],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    floatingLabelStyle: TextStyle(
                      color: Colors.blue[600], // Focused label color (blue)
                    ),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[600]!, width: 2.0),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your password';
                    }
                    if (value!.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),

                // Sign up/Sign in button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isSignUp ? 'Create Account' : 'Sign In',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
                
                const SizedBox(height: 12),

                // Toggle between sign up and sign in
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                    children: [
                      TextSpan(
                        text: _isSignUp
                            ? 'Already have an account? '
                            : 'Don\'t have an account? ',
                      ),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: _isLoading ? null : () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                            });
                          },
                          child: Text(
                            _isSignUp ? 'Sign In' : 'Sign Up',
                            style: TextStyle(
                              color: _isLoading ? Colors.grey : Colors.blue,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom flexible spacer - shrinks when keyboard appears
                Flexible(
                  flex: isKeyboardOpen ? 1 : 2,
                  child: Container(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
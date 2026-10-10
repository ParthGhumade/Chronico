import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_state.dart';
import 'main_navigation_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final AppState appState;
  const LoginScreen({super.key, required this.appState});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      TextInput.finishAutofillContext(); // Help password managers save credentials

      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MainNavigationScreen(appState: widget.appState),
            ),
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An unexpected error occurred'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      body: Stack(
        children: [
          // Background pattern
          // (In Flutter, a grid pattern background could be drawn via CustomPainter, 
          // but for simplicity we will just use a solid dark background)
          
          SafeArea(
            child: Column(
              children: [
                // TopAppBar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131313).withOpacity(0.8),
                    border: Border(bottom: BorderSide(color: const Color(0xFF424753).withOpacity(0.1))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFADC6FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFADC6FF).withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFADC6FF).withOpacity(0.15), blurRadius: 15),
                          ],
                        ),
                        child: const Icon(Icons.school, color: Color(0xFFADC6FF), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Chronico',
                        style: TextStyle(
                          color: Color(0xFFADC6FF),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content Canvas
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Subtle ambient glow effects
                            Positioned(
                              top: -80,
                              right: -80,
                              child: Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFADC6FF).withOpacity(0.15),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFFADC6FF).withOpacity(0.15), blurRadius: 80, spreadRadius: 20),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -80,
                              left: -80,
                              child: Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFFB780).withOpacity(0.1),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFFFFB780).withOpacity(0.1), blurRadius: 80, spreadRadius: 20),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Card Content
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF1C1B1B), Color(0xFF201F1F)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF424753).withOpacity(0.3)),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 20)),
                                ],
                              ),
                              padding: const EdgeInsets.all(40),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontFamily: 'Playfair Display',
                                        fontSize: 48,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xFFE5E2E1),
                                        letterSpacing: -1,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Welcome back to Chronico',
                                      style: TextStyle(
                                        color: Color(0xFFC2C6D5),
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 32),
                                    
                                    // Email Field
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4, bottom: 8),
                                      child: Text('Email', style: TextStyle(color: Color(0xFFC2C6D5), fontWeight: FontWeight.w500, fontSize: 14)),
                                    ),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [AutofillHints.email],
                                      style: const TextStyle(color: Color(0xFFE5E2E1)),
                                      decoration: InputDecoration(
                                        hintText: "name@example.com",
                                        hintStyle: TextStyle(color: const Color(0xFFC2C6D5).withOpacity(0.4)),
                                        filled: true,
                                        fillColor: const Color(0xFF0E0E0E).withOpacity(0.5),
                                        prefixIcon: Icon(Icons.mail, color: const Color(0xFFC2C6D5).withOpacity(0.5), size: 20),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: const Color(0xFF424753).withOpacity(0.5)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: const Color(0xFF424753).withOpacity(0.5)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFADC6FF)),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) return 'Please enter your email';
                                        if (!value.contains('@')) return 'Please enter a valid email';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Password Field
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4, bottom: 8),
                                      child: Text('Password', style: TextStyle(color: Color(0xFFC2C6D5), fontWeight: FontWeight.w500, fontSize: 14)),
                                    ),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      autofillHints: const [AutofillHints.password],
                                      style: const TextStyle(color: Color(0xFFE5E2E1)),
                                      decoration: InputDecoration(
                                        hintText: "••••••••",
                                        hintStyle: TextStyle(color: const Color(0xFFC2C6D5).withOpacity(0.4)),
                                        filled: true,
                                        fillColor: const Color(0xFF0E0E0E).withOpacity(0.5),
                                        prefixIcon: Icon(Icons.lock, color: const Color(0xFFC2C6D5).withOpacity(0.5), size: 20),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: const Color(0xFF424753).withOpacity(0.5)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: const Color(0xFF424753).withOpacity(0.5)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFADC6FF)),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Please enter your password';
                                        return null;
                                      },
                                      onFieldSubmitted: (_) => _submit(),
                                    ),
                                    const SizedBox(height: 32),
                                    
                                    // Submit Button
                                    ElevatedButton(
                                      onPressed: _isLoading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFADC6FF),
                                        foregroundColor: const Color(0xFF002E69),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        shadowColor: const Color(0xFFADC6FF).withOpacity(0.4),
                                        elevation: 8,
                                      ),
                                      child: _isLoading 
                                          ? const SizedBox(
                                              width: 20, 
                                              height: 20, 
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF002E69))
                                            )
                                          : const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                SizedBox(width: 8),
                                                Icon(Icons.arrow_forward, size: 18),
                                              ],
                                            ),
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Sign Up link
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      children: [
                                        const Text("Don't have an account? ", style: TextStyle(color: Color(0xFFC2C6D5))),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).pushReplacement(
                                              MaterialPageRoute(builder: (context) => SignupScreen(appState: widget.appState)),
                                            );
                                          },
                                          child: const Text(
                                            'Sign Up', 
                                            style: TextStyle(
                                              color: Color(0xFFADC6FF), 
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

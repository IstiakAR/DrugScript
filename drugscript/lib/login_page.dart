import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  // Placeholder method - no actual authentication
  void _handleGoogleSignIn() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate loading for 1 second
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Just navigate to the next screen
        Navigator.pushReplacementNamed(context, '/medicineSearch');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long, size: 64, color: Colors.deepPurple),
              const SizedBox(height: 16),
              const Text(
                'DrugScript',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Login to manage your prescription\n& reports',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Image.asset('assets/google.jpg', height: 24),
                  label: Text(_isLoading ? 'Signing in...' : 'Continue with Google'),
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('OR', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Just navigate to the next screen
                    Navigator.pushReplacementNamed(context, '/medicineSearch');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: const Text('Send OTP'),
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'By continuing, you agree to our ',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  children: [
                    TextSpan(
                      text: 'Terms',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' & '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
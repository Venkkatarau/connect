import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isOtpScreen = false;
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (isLoggedIn && mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  Future<void> _saveLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
  }

  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  int _timer = 60;
  Timer? _countdownTimer;
  bool _loading = false;
  String _error = "";

  void _startTimer() {
    _timer = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timer > 0) {
        setState(() {
          _timer--;
        });
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _mobileController.dispose();
    _passwordController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool get _isFormValid {
    return _passwordController.text.trim().isNotEmpty &&
        _mobileController.text.trim().length == 10 &&
        RegExp(r'^[0-9]+$').hasMatch(_mobileController.text.trim());
  }

  Future<void> _requestOtp() async {
    if (!_isFormValid) return;

    setState(() {
      _loading = true;
      _error = "";
    });

    final mobileNumber = _mobileController.text.trim();
    final url = Uri.parse("$baseUrl/v1/request-signup-otp?mobileNumber=$mobileNumber");

    debugPrint("[API Request] POST: $url");

    try {
      final response = await http.post(url, headers: {"Content-Type": "application/json"});
      debugPrint("[API Response] POST: $url | Status: ${response.statusCode} | Body: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Server returned status ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      if (data['status'] == false) {
        setState(() {
          _error = data['message'] ?? "Failed to request OTP";
        });
        return;
      }

      setState(() {
        _isOtpScreen = true;
      });
      _startTimer();
    } catch (e) {
      setState(() {
        _error = "Connection error. Please try again.";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _handleSignupWithOtp() async {
    final enteredOtp = _otpControllers.map((c) => c.text).join();
    if (enteredOtp.length < 4) return;

    setState(() {
      _loading = true;
      _error = "";
    });

    final url = Uri.parse("$baseUrl/v1/signup");
    final body = jsonEncode({
      "username": "Admin",
      "mobileNumber": _mobileController.text.trim(),
      "otp": enteredOtp,
      "userType": "Admin"
    });

    debugPrint("[API Request] POST: $url | Body: $body");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      debugPrint("[API Response] POST: $url | Status: ${response.statusCode} | Body: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Server error ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      if (data['status'] == false) {
        final String message = data['message'] ?? '';
        if (message.contains("already registered")) {
          await _saveLoginSession();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          }
          return;
        }
        setState(() {
          _error = message;
        });
        return;
      }

      await _saveLoginSession();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      setState(() {
        _error = "Authentication failed. Please try again.";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildOtpInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          width: 50,
          height: 55,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            keyboardType: TextInputType.number,
            maxLength: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: "",
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF225663), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                if (index < 3) {
                  _otpFocusNodes[index + 1].requestFocus();
                } else {
                  _otpFocusNodes[index].unfocus();
                  _handleSignupWithOtp();
                }
              } else if (value.isEmpty && index > 0) {
                _otpFocusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF225663),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.admin_panel_settings, size: 80, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      "ConnectThrive Admin",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isOtpScreen) ...[
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Color(0xFF225663)),
                              onPressed: () {
                                setState(() {
                                  _isOtpScreen = false;
                                  _error = "";
                                });
                              },
                            ),
                            const Expanded(
                              child: Text(
                                "Verification",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 48), // balance back button
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Enter the OTP received on +91 ${_mobileController.text}",
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _buildOtpInputs(),
                        if (_error.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text(
                          "Resend OTP in 00:${_timer < 10 ? '0$_timer' : _timer}",
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        const Text(
                          "Login or Signup",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Text("+91", style: TextStyle(fontSize: 16, color: Colors.black)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _mobileController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Enter Mobile Number",
                                    counterText: "",
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter password",
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        if (_error.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: (_isFormValid && !_loading) ? _requestOtp : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF225663),
                            disabledBackgroundColor: Colors.grey[300],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text("GET OTP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

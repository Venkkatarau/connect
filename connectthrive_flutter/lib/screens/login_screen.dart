import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../config/global_user.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isOtpScreen = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  int _timerSeconds = 60;
  Timer? _timer;
  bool _loading = false;
  String _error = "";

  void _startTimer() {
    _timerSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        setState(() {
          _timer?.cancel();
        });
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _usernameController.dispose();
    _mobileController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchAndSetUser(String name, String phone) async {
    try {
      final url = '$baseUrl/v1/user/by-mobile?mobileNumber=$phone';
      debugPrint("[API Request] GET: $url");
      final res = await http.get(Uri.parse(url));
      debugPrint(
        "[API Response] GET: $url | Status: ${res.statusCode} | Body: ${res.body}",
      );
      if (res.statusCode == 200) {
        final userDetails = json.decode(res.body);
        GlobalUser.setGlobalUser(
          username: userDetails['username'] ?? name,
          mobileNumber: userDetails['mobileNumber'] ?? phone,
          userId: userDetails['id'] ?? 0,
          batchId: userDetails['batchId'] ?? 2,
        );
      } else {
        GlobalUser.setGlobalUser(username: name, mobileNumber: phone);
      }
    } catch (e) {
      debugPrint("Failed to fetch dynamic user info: $e");
      GlobalUser.setGlobalUser(username: name, mobileNumber: phone);
    }
  }

  Future<void> _handleSignupWithOtp(String enteredOtp) async {
    setState(() {
      _loading = true;
      _error = "";
    });

    try {
      final url = '$baseUrl/v1/signup';
      final payload = {
        "username": _usernameController.text,
        "mobileNumber": _mobileController.text,
        "otp": enteredOtp,
        "userType": "student",
      };
      debugPrint("[API Request] POST: $url | Body: ${json.encode(payload)}");
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );

      debugPrint(
        "[API Response] POST: $url | Status: ${response.statusCode} | Body: ${response.body}",
      );
      final data = json.decode(response.body);

      if (response.statusCode != 200) {
        setState(() {
          _error = "Something went wrong. Please try again.";
        });
        return;
      }

      if (data['status'] == false) {
        final String message = data['message'] ?? '';
        if (message.contains("already registered")) {
          await _fetchAndSetUser(
            _usernameController.text,
            _mobileController.text,
          );
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          }
          return;
        }
        setState(() {
          _error = message;
        });
        return;
      }

      await _fetchAndSetUser(_usernameController.text, _mobileController.text);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _error = "Connection failed. Please check your internet.";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _requestOtp() async {
    final phone = _mobileController.text.trim();
    if (_usernameController.text.trim().isEmpty || phone.length != 10) {
      return;
    }

    setState(() {
      _loading = true;
      _error = "";
    });

    try {
      final url = '$baseUrl/v1/request-signup-otp?mobileNumber=$phone';
      debugPrint("[API Request] POST: $url");
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      debugPrint(
        "[API Response] POST: $url | Status: ${response.statusCode} | Body: ${response.body}",
      );
      final data = json.decode(response.body);
      if (data['status'] == false) {
        setState(() {
          _error = data['message'] ?? "Failed to request OTP.";
        });
        return;
      }

      setState(() {
        _isOtpScreen = true;
        _startTimer();
        for (var c in _otpControllers) {
          c.clear();
        }
      });
    } catch (e) {
      setState(() {
        _error = "Error connecting to server.";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildTopBanner() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.35,
      color: const Color(0xFF225663),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school_outlined, size: 64, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            "ConnectThrive",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Master Oracle Fusion Financials",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginInputCard() {
    final isFormValid =
        _usernameController.text.trim().isNotEmpty &&
        _mobileController.text.trim().length == 10;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Login or Signup",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF225663),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _usernameController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_outline),
              hintText: "Enter Username",
              filled: true,
              fillColor: const Color(0xFFF3F3F3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  "+91",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              hintText: "Enter Mobile Number",
              counterText: "",
              filled: true,
              fillColor: const Color(0xFFF3F3F3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_error.isNotEmpty) ...[
            Text(
              _error,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton(
            onPressed: (isFormValid && !_loading) ? _requestOtp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF225663),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    "GET OTP",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isOtpScreen = false;
                    _error = "";
                  });
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF225663),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "OTP Verification",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF225663),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Enter OTP received on +91 ${_mobileController.text}",
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return SizedBox(
                width: 55,
                height: 55,
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLength: 1,
                  decoration: InputDecoration(
                    counterText: "",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF225663),
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      if (index < 3) {
                        _otpFocusNodes[index + 1].requestFocus();
                      } else {
                        FocusScope.of(context).unfocus();
                        final fullOtp = _otpControllers
                            .map((c) => c.text)
                            .join();
                        _handleSignupWithOtp(fullOtp);
                      }
                    } else if (index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          if (_error.isNotEmpty) ...[
            Text(
              _error,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          if (_timerSeconds > 0) ...[
            Text(
              "Resend OTP in 00:${_timerSeconds < 10 ? '0$_timerSeconds' : _timerSeconds}",
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive OTP? "),
                GestureDetector(
                  onTap: _requestOtp,
                  child: const Text(
                    "Resend Now",
                    style: TextStyle(
                      color: Color(0xFF225663),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF225663)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopBanner(),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: _isOtpScreen ? _buildOtpCard() : _buildLoginInputCard(),
            ),
          ],
        ),
      ),
    );
  }
}

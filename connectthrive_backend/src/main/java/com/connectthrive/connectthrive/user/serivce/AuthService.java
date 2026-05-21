package com.connectthrive.connectthrive.user.serivce;

import com.connectthrive.connectthrive.user.model.LoginResponse;
import com.connectthrive.connectthrive.user.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import com.connectthrive.connectthrive.user.model.User;

import java.util.Optional;
import java.util.UUID;

@Service
public class AuthService {
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private OtpService otpService;

    public ResponseEntity<LoginResponse> requestSignupOtp(String mobileNumber) {
       String response= otpService.createOtp(mobileNumber);
        if(response.contains("Success")) {
           return ResponseEntity.ok(new LoginResponse(true, "OTP send to your mobile number!!!!"));
        }else{
            return ResponseEntity.ok(new LoginResponse(false, response));
        }
    }

    public ResponseEntity<LoginResponse> signup(String username, String mobileNumber, String otp,String userType) {
        if (!otpService.verifyOtp(mobileNumber, otp)) {
            return ResponseEntity.ok(new LoginResponse(false, "Invalid OTP"));
        }

        if (userRepository.findByMobileNumber(mobileNumber).isPresent()) {
            return ResponseEntity.ok(new LoginResponse(false, "Mobile number already registered!!!!"));
        }

        User user = new User();
        user.setUsername(username);
        user.setMobileNumber(mobileNumber);
        user.setUserType(userType);
        user.setVerified(true);
        String sessionToken = UUID.randomUUID().toString();
        user.setActiveSessionToken(sessionToken);
        userRepository.save(user);

        return ResponseEntity.ok(new LoginResponse(true, "Registration done successfully!!!!"));
    }

    public String login(String mobileOrEmail, String password) {
        Optional<User> userOpt = mobileOrEmail.contains("@")
                ? userRepository.findByEmail(mobileOrEmail)
                : userRepository.findByMobileNumber(mobileOrEmail);

        if (userOpt.isEmpty()) return "Invalid credentials";

        User user = userOpt.get();

        if (!passwordEncoder.matches(password, user.getPassword())) {
            return "Invalid credentials";
        }

        if (user.getActiveSessionToken() != null) {
            return "User already logged in on another device";
        }

        String sessionToken = UUID.randomUUID().toString(); // Or generate JWT token
        user.setActiveSessionToken(sessionToken);
        userRepository.save(user);

        return "Login successful. Token: " + sessionToken;
    }

    public String forgotPassword(String mobileNumber) {
        Optional<User> user = userRepository.findByMobileNumber(mobileNumber);
        if (user.isPresent()) {
            otpService.createOtp(mobileNumber);
            return "OTP sent";
        }
        return "User not found";
    }

    public String resetPassword(String mobileNumber, String otp, String newPassword) {
        if (!otpService.verifyOtp(mobileNumber, otp)) {
            return "Invalid OTP";
        }

        Optional<User> user = userRepository.findByMobileNumber(mobileNumber);
        if (user.isPresent()) {
            user.get().setPassword(passwordEncoder.encode(newPassword));
            userRepository.save(user.get());
            return "Password reset successful";
        }

        return "User not found";
    }

    public String logout(String token) {
        Optional<User> userOpt = userRepository.findAll()
                .stream()
                .filter(user -> token.equals(user.getActiveSessionToken()))
                .findFirst();

        if (userOpt.isEmpty()) {
            return "Invalid session token";
        }

        User user = userOpt.get();
        user.setActiveSessionToken(null);
        userRepository.save(user);

        return "Logged out successfully";
    }
}
package com.connectthrive.connectthrive.user;

import com.connectthrive.connectthrive.user.model.LoginRequest;
import com.connectthrive.connectthrive.user.model.LoginResponse;
import com.connectthrive.connectthrive.user.model.SignupRequest;
import com.connectthrive.connectthrive.user.serivce.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/v1")
public class LoginController {

    @Autowired
    private AuthService authService;

    @PostMapping("/request-signup-otp")
    public ResponseEntity<LoginResponse> requestSignupOtp(@RequestParam String mobileNumber) {
        return authService.requestSignupOtp(mobileNumber);

    }

    @PostMapping("/signup")
    public ResponseEntity<LoginResponse> signup(@RequestBody SignupRequest request) {
        return authService.signup(
                request.getUsername(),
                request.getMobileNumber(),
                request.getOtp(),
                request.getUserType());
    }

    @PostMapping("/login")
    public ResponseEntity<String> login(@RequestParam String user, @RequestParam String password) {
        return ResponseEntity.ok(authService.login(user, password));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<String> forgotPassword(@RequestParam String mobileNumber) {
        return ResponseEntity.ok(authService.forgotPassword(mobileNumber));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<String> resetPassword(@RequestParam String mobileNumber, @RequestParam String otp,
            @RequestParam String newPassword) {
        return ResponseEntity.ok(authService.resetPassword(mobileNumber, otp, newPassword));
    }

    @PostMapping(value = "/admin/login", produces = MediaType.APPLICATION_JSON_VALUE, consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<LoginResponse> adminLogin(@RequestBody LoginRequest loginRequest) {

        try {
            if ("admin".equals(loginRequest.getUsername()) && "admin".equals(loginRequest.getPassword())) {
                return ResponseEntity.ok(new LoginResponse(true, "Login successful"));
            } else {
                return ResponseEntity.status(401).body(new LoginResponse(false, "Invalid username or password!!!"));
            }

        } catch (Exception ex) {
            return ResponseEntity.status(500).body(new LoginResponse(false, "OOPS!!! something went wrong!!!"));
        }

    }

    @PostMapping("/logout")
    public ResponseEntity<String> logout(@RequestParam String token) {
        return ResponseEntity.ok(authService.logout(token));
    }
}

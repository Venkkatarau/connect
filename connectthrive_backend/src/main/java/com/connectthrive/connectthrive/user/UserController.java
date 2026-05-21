package com.connectthrive.connectthrive.user;

import com.connectthrive.connectthrive.user.model.User;
import com.connectthrive.connectthrive.user.repository.UserRepository;
import com.connectthrive.connectthrive.adminlatest.entity.Batch;
import com.connectthrive.connectthrive.adminlatest.repository.BatchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1")
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BatchRepository batchRepository;

    @GetMapping("/getUserList")
    public ResponseEntity<List<Map<String, Object>>> getUserList() {
        List<User> users = userRepository.findAll();
        List<Map<String, Object>> response = new ArrayList<>();
        
        for (User user : users) {
            // Filter to only include 'student' type users if needed, or all users
            if ("student".equalsIgnoreCase(user.getUserType())) {
                Map<String, Object> map = new HashMap<>();
                map.put("id", user.getId());
                map.put("username", user.getUsername());
                map.put("mobileNumber", user.getMobileNumber());
                
                Batch batch = user.getBatch();
                if (batch != null) {
                    map.put("batchId", batch.getId());
                    map.put("batchName", batch.getName());
                } else {
                    map.put("batchId", null);
                    map.put("batchName", "No Batch Assigned");
                }
                response.add(map);
            }
        }
        return ResponseEntity.ok(response);
    }

    @GetMapping("/user/by-mobile")
    public ResponseEntity<?> getUserByMobile(@RequestParam String mobileNumber) {
        return userRepository.findByMobileNumber(mobileNumber)
                .map(user -> {
                    Map<String, Object> map = new HashMap<>();
                    map.put("id", user.getId());
                    map.put("username", user.getUsername());
                    map.put("mobileNumber", user.getMobileNumber());
                    Batch batch = user.getBatch();
                    if (batch != null) {
                        map.put("batchId", batch.getId());
                        map.put("batchName", batch.getName());
                    } else {
                        map.put("batchId", null);
                        map.put("batchName", "No Batch Assigned");
                    }
                    return ResponseEntity.ok(map);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/users/updateBatch/{id}")
    public ResponseEntity<?> updateBatch(@PathVariable Long id, @RequestParam Long batchId) {
        try {
            User user = userRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            Batch batch = batchRepository.findById(batchId)
                    .orElseThrow(() -> new RuntimeException("Batch not found"));
            
            user.setBatch(batch);
            userRepository.save(user);
            
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}

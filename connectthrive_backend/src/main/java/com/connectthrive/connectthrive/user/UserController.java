package com.connectthrive.connectthrive.user;

import com.connectthrive.connectthrive.user.model.User;
import com.connectthrive.connectthrive.user.repository.UserRepository;
import com.connectthrive.connectthrive.adminlatest.entity.Batch;
import com.connectthrive.connectthrive.adminlatest.repository.BatchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

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
                response.add(toUserResponse(user));
            }
        }
        return ResponseEntity.ok(response);
    }

    @GetMapping("/user/by-mobile")
    public ResponseEntity<?> getUserByMobile(@RequestParam String mobileNumber) {
        return userRepository.findByMobileNumber(mobileNumber)
                .map(user -> ResponseEntity.ok(toUserResponse(user)))
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/users/updateBatch/{id}")
    public ResponseEntity<?> updateBatch(
            @PathVariable Long id,
            @RequestParam(required = false) Long batchId,
            @RequestParam(required = false) List<Long> batchIds
    ) {
        try {
            User user = userRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            List<Long> requestedBatchIds = normalizeBatchIds(batchId, batchIds);
            Set<Batch> resolvedBatches = new LinkedHashSet<>();

            for (Long requestedBatchId : requestedBatchIds) {
                Batch batch = batchRepository.findById(requestedBatchId)
                        .orElseThrow(() -> new RuntimeException("Batch not found: " + requestedBatchId));
                resolvedBatches.add(batch);
            }

            user.setBatches(resolvedBatches);
            userRepository.save(user);

            return ResponseEntity.ok(toUserResponse(user));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    private List<Long> normalizeBatchIds(Long batchId, List<Long> batchIds) {
        List<Long> normalized = new ArrayList<>();

        if (batchIds != null) {
            normalized.addAll(batchIds.stream()
                    .filter(id -> id != null)
                    .toList());
        }

        if (batchId != null) {
            normalized.add(batchId);
        }

        List<Long> deduplicated = normalized.stream()
                .distinct()
                .toList();

        if (deduplicated.isEmpty()) {
            throw new RuntimeException("At least one batchId is required");
        }

        return deduplicated;
    }

    private Map<String, Object> toUserResponse(User user) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", user.getId());
        map.put("username", user.getUsername());
        map.put("mobileNumber", user.getMobileNumber());

        List<Map<String, Object>> batches = user.getBatches().stream()
                .map(this::toBatchSummary)
                .toList();

        Batch primaryBatch = user.getBatch();
        if (primaryBatch != null) {
            map.put("batchId", primaryBatch.getId());
            map.put("batchName", primaryBatch.getName());
        } else {
            map.put("batchId", null);
            map.put("batchName", "No Batch Assigned");
        }

        map.put("batchIds", batches.stream()
                .map(batch -> (Long) batch.get("id"))
                .collect(Collectors.toList()));
        map.put("batchNames", batches.stream()
                .map(batch -> (String) batch.get("name"))
                .collect(Collectors.toList()));
        map.put("batches", batches);
        return map;
    }

    private Map<String, Object> toBatchSummary(Batch batch) {
        Map<String, Object> batchMap = new HashMap<>();
        batchMap.put("id", batch.getId());
        batchMap.put("name", batch.getName());
        return batchMap;
    }
}

package com.connectthrive.connectthrive.adminlatest.controller;

import com.connectthrive.connectthrive.adminlatest.entity.CourseModule;
import com.connectthrive.connectthrive.adminlatest.entity.ModuleAccessRequest;
import com.connectthrive.connectthrive.adminlatest.service.ModuleAccessService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;
import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/api/modules")
public class ModuleAccessController {

    @Autowired
    private ModuleAccessService accessService;

    @PostMapping("/{moduleId}/request-access")
    public ResponseEntity<Map<String, Object>> requestAccess(@RequestParam Long userId, @PathVariable Long moduleId) {
        Map<String, Object> response = new HashMap<>();
        try {
            String result = accessService.requestModuleAccess(userId, moduleId);
            response.put("status", true);
            response.put("message", result);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("status", false);
            response.put("message", e.getMessage());
            return ResponseEntity.ok(response);
        }
    }

    @RequestMapping(value = "/approve/{requestId}", method = {RequestMethod.GET, RequestMethod.POST})
    public ResponseEntity<Map<String, Object>> approve(@PathVariable Long requestId) {
        Map<String, Object> response = new HashMap<>();
        try {
            String result = accessService.approveRequest(requestId);
            response.put("status", true);
            response.put("message", result);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("status", false);
            response.put("message", e.getMessage());
            return ResponseEntity.ok(response);
        }
    }

    @GetMapping("/pending-requests")
    public List<ModuleAccessRequest> getPendingRequests() {
        return accessService.getPendingRequests();
    }
}

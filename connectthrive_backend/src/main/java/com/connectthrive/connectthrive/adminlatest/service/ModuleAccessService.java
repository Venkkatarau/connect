package com.connectthrive.connectthrive.adminlatest.service;

import com.connectthrive.connectthrive.adminlatest.entity.CourseModule;
import com.connectthrive.connectthrive.adminlatest.entity.ModuleAccessRequest;
import com.connectthrive.connectthrive.adminlatest.repository.ModuleAccessRequestRepository;
import com.connectthrive.connectthrive.adminlatest.repository.ModuleRepository;
import com.connectthrive.connectthrive.user.model.User;
import com.connectthrive.connectthrive.user.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class ModuleAccessService {

    @Autowired
    private ModuleAccessRequestRepository accessRepo;

    @Autowired
    private ModuleRepository moduleRepo;

    @Autowired
    private UserRepository userRepo;

    public String requestModuleAccess(Long userId, Long moduleId) {
        Optional<CourseModule> moduleOpt = moduleRepo.findById(moduleId);
        Optional<User> userOpt = userRepo.findById(userId);

        if (moduleOpt.isEmpty() || userOpt.isEmpty()) return "Invalid user/module";

        CourseModule module = moduleOpt.get();
        if ("free".equalsIgnoreCase(module.getTier())) {
            return "Access granted: Free module";
        }

        if (accessRepo.findByStudentIdAndModuleId(userId, moduleId).isPresent()) {
            return "Already requested or approved";
        }

        ModuleAccessRequest request = new ModuleAccessRequest();
        request.setStudent(userOpt.get());
        request.setModule(module);
        request.setApproved(false);
        request.setRequestedAt(LocalDateTime.now());

        accessRepo.save(request);
        return "Access request sent to admin";
    }

    public String approveRequest(Long requestId) {
        ModuleAccessRequest request = accessRepo.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Request not found"));
        request.setApproved(true);
        accessRepo.save(request);
        return "Access approved";
    }

    public List<ModuleAccessRequest> getPendingRequests() {
        return accessRepo.findAll().stream()
                .filter(req -> !req.isApproved())
                .collect(Collectors.toList());
    }
}

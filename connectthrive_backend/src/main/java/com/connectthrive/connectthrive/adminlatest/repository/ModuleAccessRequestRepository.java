package com.connectthrive.connectthrive.adminlatest.repository;

import com.connectthrive.connectthrive.adminlatest.entity.ModuleAccessRequest;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ModuleAccessRequestRepository extends JpaRepository<ModuleAccessRequest, Long> {
    List<ModuleAccessRequest> findByStudentId(Long studentId);
    Optional<ModuleAccessRequest> findByStudentIdAndModuleId(Long studentId, Long moduleId);
}

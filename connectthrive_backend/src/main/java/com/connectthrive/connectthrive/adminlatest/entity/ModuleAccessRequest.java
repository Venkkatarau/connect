package com.connectthrive.connectthrive.adminlatest.entity;

import jakarta.persistence.*;
import com.connectthrive.connectthrive.user.model.User;

import java.time.LocalDateTime;

@Entity
public class ModuleAccessRequest {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    private User student;

    @ManyToOne
    private CourseModule module;

    private boolean isApproved;

    private LocalDateTime requestedAt;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    @com.fasterxml.jackson.annotation.JsonIgnore
    public User getStudent() {
        return student;
    }

    public void setStudent(User student) {
        this.student = student;
    }

    @com.fasterxml.jackson.annotation.JsonIgnore
    public CourseModule getModule() {
        return module;
    }

    public void setModule(CourseModule module) {
        this.module = module;
    }

    public String getUsername() {
        return student != null ? student.getUsername() : null;
    }

    public String getMobileNumber() {
        return student != null ? student.getMobileNumber() : null;
    }

    public String getModuleName() {
        return module != null ? module.getName() : null;
    }

    public boolean isApproved() {
        return isApproved;
    }

    public void setApproved(boolean approved) {
        isApproved = approved;
    }

    public LocalDateTime getRequestedAt() {
        return requestedAt;
    }

    public void setRequestedAt(LocalDateTime requestedAt) {
        this.requestedAt = requestedAt;
    }
}

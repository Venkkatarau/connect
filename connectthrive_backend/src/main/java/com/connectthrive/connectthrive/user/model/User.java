package com.connectthrive.connectthrive.user.model;

import jakarta.persistence.*;

import java.util.LinkedHashSet;
import java.util.Set;

@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String username;
    private String email;

    @Column(unique = true)
    private String mobileNumber;

    private String password;

    private boolean isVerified;

    private String userType;

    private String activeSessionToken;

    @ManyToOne
    @JoinColumn(name = "batch_id")
    private com.connectthrive.connectthrive.adminlatest.entity.Batch batch;

    @ManyToMany
    @JoinTable(
            name = "user_batches",
            joinColumns = @JoinColumn(name = "user_id"),
            inverseJoinColumns = @JoinColumn(name = "batch_id")
    )
    private Set<com.connectthrive.connectthrive.adminlatest.entity.Batch> batches = new LinkedHashSet<>();

    public com.connectthrive.connectthrive.adminlatest.entity.Batch getBatch() {
        if (batch != null) {
            return batch;
        }
        return batches.stream().findFirst().orElse(null);
    }

    public Set<com.connectthrive.connectthrive.adminlatest.entity.Batch> getBatches() {
        if (batches.isEmpty() && batch != null) {
            batches.add(batch);
        }
        return batches;
    }

    public void setBatches(Set<com.connectthrive.connectthrive.adminlatest.entity.Batch> batches) {
        this.batches.clear();
        if (batches != null) {
            this.batches.addAll(batches);
        }
        this.batch = this.batches.stream().findFirst().orElse(null);
    }

    public void addBatch(com.connectthrive.connectthrive.adminlatest.entity.Batch batch) {
        if (batch == null) {
            return;
        }
        this.batches.add(batch);
        if (this.batch == null) {
            this.batch = batch;
        }
    }

    public void clearBatches() {
        this.batches.clear();
        this.batch = null;
    }

    public void setBatch(com.connectthrive.connectthrive.adminlatest.entity.Batch batch) {
        this.batch = batch;
        this.batches.clear();
        if (batch != null) {
            this.batches.add(batch);
        }
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getMobileNumber() {
        return mobileNumber;
    }

    public void setMobileNumber(String mobileNumber) {
        this.mobileNumber = mobileNumber;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public boolean isVerified() {
        return isVerified;
    }

    public void setVerified(boolean verified) {
        isVerified = verified;
    }

    public String getUserType() {
        return userType;
    }

    public void setUserType(String userType) {
        this.userType = userType;
    }

    public String getActiveSessionToken() {
        return activeSessionToken;
    }

    public void setActiveSessionToken(String activeSessionToken) {
        this.activeSessionToken = activeSessionToken;
    }
}
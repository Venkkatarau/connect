package com.connectthrive.connectthrive.adminlatest.entity;

import jakarta.persistence.*;

import java.util.HashSet;
import java.util.Set;

@Entity
public class Batch {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    @ManyToMany
    @JoinTable(
            name = "batch_concepts",
            joinColumns = @JoinColumn(name = "batch_id"),
            inverseJoinColumns = @JoinColumn(name = "concept_id")
    )
    private Set<Concept> accessibleConcepts = new HashSet<>();

    public Set<Concept> getAccessibleConcepts() {
        return accessibleConcepts;
    }

    public void setAccessibleConcepts(Set<Concept> accessibleConcepts) {
        this.accessibleConcepts = accessibleConcepts;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
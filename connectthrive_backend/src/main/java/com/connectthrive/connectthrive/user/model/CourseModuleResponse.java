package com.connectthrive.connectthrive.user.model;

import com.connectthrive.connectthrive.adminlatest.model.ConceptDTO;

import java.util.ArrayList;
import java.util.List;

public class CourseModuleResponse {
    private Long id;
    private String name;
    private String description;
    private String tier;
    private boolean accessible;

    private List<ConceptDTO> concepts = new ArrayList<>();
    private List<ConceptDTO> transactionConcepts = new ArrayList<>();

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

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getTier() {
        return tier;
    }

    public void setTier(String tier) {
        this.tier = tier;
    }

    public boolean isAccessible() {
        return accessible;
    }

    public void setAccessible(boolean accessible) {
        this.accessible = accessible;
    }

    public List<ConceptDTO> getConcepts() {
        return concepts;
    }

    public void setConcepts(List<ConceptDTO> concepts) {
        this.concepts = concepts;
    }

    public List<ConceptDTO> getTransactionConcepts() {
        return transactionConcepts;
    }

    public void setTransactionConcepts(List<ConceptDTO> transactionConcepts) {
        this.transactionConcepts = transactionConcepts;
    }
}

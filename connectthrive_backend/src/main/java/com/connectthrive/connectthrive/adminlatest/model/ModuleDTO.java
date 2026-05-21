package com.connectthrive.connectthrive.adminlatest.model;

import java.util.ArrayList;
import java.util.List;


public class ModuleDTO {
    private Long id;
    private String name, tier;
    private String description;
    private boolean accessible;
    private List<ConceptDTO> concepts = new ArrayList<>();
    private List<ConceptDTO> transactionConcepts = new ArrayList<>();

    public List<ConceptDTO> getTransactionConcepts() {
        return transactionConcepts;
    }

    public void setTransactionConcepts(List<ConceptDTO> transactionConcepts) {
        this.transactionConcepts = transactionConcepts;
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

    public String getTier() {
        return tier;
    }

    public void setTier(String tier) {
        this.tier = tier;
    }

    public List<ConceptDTO> getConcepts() {
        return concepts;
    }

    public void setConcepts(List<ConceptDTO> concepts) {
        this.concepts = concepts;
    }
    public void addConcept(ConceptDTO concepts) {
        this.concepts.add(concepts);
    }

    public void addTranasactionConcept(ConceptDTO concepts) {
        this.transactionConcepts.add(concepts);
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public boolean isAccessible() {
        return accessible;
    }

    public void setAccessible(boolean accessible) {
        this.accessible = accessible;
    }
}
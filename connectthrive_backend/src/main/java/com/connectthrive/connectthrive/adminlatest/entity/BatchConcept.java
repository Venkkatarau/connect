package com.connectthrive.connectthrive.adminlatest.entity;

import jakarta.persistence.*;

import jakarta.persistence.*;

@Entity
@Table(name = "batch_concepts")
public class BatchConcept {

    @EmbeddedId
    private BatchConceptKey id;

    public BatchConcept() {}

    public BatchConcept(Long batchId, Long conceptId) {
        this.id = new BatchConceptKey(batchId, conceptId);
    }

    public BatchConceptKey getId() {
        return id;
    }

    public void setId(BatchConceptKey id) {
        this.id = id;
    }

    // Convenience methods
    public Long getBatchId() {
        return id.getBatchId();
    }

    public Long getConceptId() {
        return id.getConceptId();
    }
}

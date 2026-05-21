package com.connectthrive.connectthrive.adminlatest.entity;

import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class BatchConceptKey implements Serializable {

    private Long batch_Id;
    private Long concept_Id;

    public BatchConceptKey() {}

    public BatchConceptKey(Long batch_Id, Long concept_Id) {
        this.batch_Id = batch_Id;
        this.concept_Id = concept_Id;
    }

    // equals() and hashCode() are REQUIRED for composite key to work
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof BatchConceptKey that)) return false;
        return Objects.equals(batch_Id, that.batch_Id) &&
                Objects.equals(concept_Id, that.concept_Id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(batch_Id, concept_Id);
    }

    // Getters and Setters
    public Long getBatchId() {
        return batch_Id;
    }

    public void setBatchId(Long batch_Id) {
        this.batch_Id = batch_Id;
    }

    public Long getConceptId() {
        return concept_Id;
    }

    public void setConceptId(Long concept_Id) {
        this.concept_Id = concept_Id;
    }
}

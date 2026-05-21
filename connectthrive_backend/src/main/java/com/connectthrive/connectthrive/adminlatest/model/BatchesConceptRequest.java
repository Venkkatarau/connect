package com.connectthrive.connectthrive.adminlatest.model;

import java.util.List;

public class BatchesConceptRequest {
    private List<Long> batchId;
    private Long conceptIds;

    // Getters and Setters
    public List<Long> getBatchId() {
        return batchId;
    }

    public void setBatchId(List<Long> batchId) {
        this.batchId = batchId;
    }

    public Long getConceptIds() {
        return conceptIds;
    }

    public void setConceptIds(Long conceptIds) {
        this.conceptIds = conceptIds;
    }
}

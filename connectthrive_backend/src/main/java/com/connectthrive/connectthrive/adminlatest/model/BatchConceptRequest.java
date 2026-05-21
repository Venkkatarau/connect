package com.connectthrive.connectthrive.adminlatest.model;

import java.util.List;

public class BatchConceptRequest {
    private Long batchId;
    private List<Long> conceptIds;

    public Long getBatchId() {
        return batchId;
    }

    public List<Long> getConceptIds() {
        return conceptIds;
    }
}

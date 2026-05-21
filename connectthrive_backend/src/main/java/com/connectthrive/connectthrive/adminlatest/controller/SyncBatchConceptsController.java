package com.connectthrive.connectthrive.adminlatest.controller;

import com.connectthrive.connectthrive.adminlatest.entity.BatchConcept;
import com.connectthrive.connectthrive.adminlatest.model.BatchesConceptRequest;
import com.connectthrive.connectthrive.adminlatest.repository.BatchConceptRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/v1/admin")
public class SyncBatchConceptsController {
    @Autowired
    private BatchConceptRepository repository;
    @PostMapping("/syncBatchConcepts")
    public ResponseEntity<String> syncBatchConcepts(@RequestBody BatchesConceptRequest request) {
        List<Long> batchIds = request.getBatchId();
        Long conceptId = request.getConceptIds();

        // 1. Remove records for this conceptId that are not in batchIds
        repository.deleteNotInBatchIds(conceptId, batchIds);

        // 2. Add missing entries (idempotent, can add duplicate check if needed)
        for (Long batchId : batchIds) {
            boolean exists = repository.existsMapping(batchId, conceptId);
            if (!exists) {
                repository.insertMapping(batchId, conceptId);
            }
        }

        return ResponseEntity.ok("Batch-Concepts synced successfully");
    }

}

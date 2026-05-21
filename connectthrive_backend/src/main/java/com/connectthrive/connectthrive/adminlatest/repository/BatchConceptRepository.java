package com.connectthrive.connectthrive.adminlatest.repository;

import com.connectthrive.connectthrive.adminlatest.entity.BatchConcept;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

public interface BatchConceptRepository {


    void deleteNotInBatchIds(Long conceptId, List<Long> batchIds);
    boolean existsMapping(Long batchId, Long conceptId);
    void insertMapping(Long batchId, Long conceptId);

}
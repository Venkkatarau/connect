package com.connectthrive.connectthrive.adminlatest.repository;

import com.connectthrive.connectthrive.adminlatest.entity.Batch;
import com.connectthrive.connectthrive.adminlatest.model.GetBatch;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface BatchRepository extends JpaRepository<Batch, Long> {

    @Query(value = "SELECT id AS id, name AS name FROM batch", nativeQuery = true)
    List<GetBatch> findAllBatches();

    @Query("SELECT b FROM Batch b JOIN b.accessibleConcepts c WHERE c.id = :conceptId")
    List<GetBatch> findByConceptId(@Param("conceptId") Long conceptId);
}

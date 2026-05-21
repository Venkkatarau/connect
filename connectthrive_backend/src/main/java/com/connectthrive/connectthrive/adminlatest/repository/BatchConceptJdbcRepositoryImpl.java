package com.connectthrive.connectthrive.adminlatest.repository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class BatchConceptJdbcRepositoryImpl implements BatchConceptRepository {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public void deleteNotInBatchIds(Long conceptId, List<Long> batchIds) {
        if (batchIds.isEmpty()) {
            jdbcTemplate.update("DELETE FROM batch_concepts WHERE concept_id = ?", conceptId);
        } else {
            String inSql = String.join(",", batchIds.stream().map(id -> "?").toList());
            String sql = "DELETE FROM batch_concepts WHERE concept_id = ? AND batch_id NOT IN (" + inSql + ")";
            jdbcTemplate.update(sql, prepend(conceptId, batchIds.toArray()));
        }
    }

    @Override
    public boolean existsMapping(Long batchId, Long conceptId) {
        String sql = "SELECT COUNT(*) FROM batch_concepts WHERE batch_id = ? AND concept_id = ?";
        Integer count = jdbcTemplate.queryForObject(sql, Integer.class, batchId, conceptId);
        return count != null && count > 0;
    }

    @Override
    public void insertMapping(Long batchId, Long conceptId) {
        String sql = "INSERT INTO batch_concepts (batch_id, concept_id) VALUES (?, ?)";
        jdbcTemplate.update(sql, batchId, conceptId);
    }

    // Utility to prepend conceptId to Object[]
    private Object[] prepend(Long conceptId, Object[] batchIds) {
        Object[] result = new Object[batchIds.length + 1];
        result[0] = conceptId;
        System.arraycopy(batchIds, 0, result, 1, batchIds.length);
        return result;
    }
}

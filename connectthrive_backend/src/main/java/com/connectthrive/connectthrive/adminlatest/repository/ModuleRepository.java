package com.connectthrive.connectthrive.adminlatest.repository;

import com.connectthrive.connectthrive.adminlatest.model.ConceptModuleDTO;
import com.connectthrive.connectthrive.adminlatest.model.ModuleDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import com.connectthrive.connectthrive.adminlatest.entity.CourseModule;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ModuleRepository extends JpaRepository<CourseModule, Long> {

    @Query(value = "SELECT id AS id, name AS name, tier AS tier, description AS description FROM course_module", nativeQuery = true)
    List<ConceptModuleDTO> findAllModuleDTOs();

    @Query(value = "SELECT" +
            "  m.name," +
            "  m.id," +
            "  m.tier," +
            "  c.title," +
            "  c.id AS courseId," +
            "  c.video_file_name AS videoFileName," +
            "  sd.supporting_document As supportingDocuments," +
            "  c.thumbnail_file_name As thumbnailFileName," +
            "  c.video_type As videoType," +
            "  m.description As description" +
            " FROM course_module m" +
            " JOIN concept c ON c.module_id = m.id" +
            " LEFT JOIN concept_supporting_document sd ON sd.concept_id = c.id;", nativeQuery = true)
    List<Object[]> findAllWithConcepts();

    List<CourseModule> findByCourseId(Long courseId);


//    @Query(value = "WITH accessible_modules AS ( " +
//            "SELECT m.id AS module_id " +
//            "FROM course_module m " +
//            "WHERE LOWER(m.tier) = 'free' " +
//            "UNION " +
//            "SELECT mar.module_id " +
//            "FROM module_access_request mar " +
//            "WHERE mar.student_id = :userId AND mar.approved = true " +
//            ") " +
//            "SELECT cm.id AS module_id, " +
//            "cm.name AS module_name, " +
//            "cm.description AS module_description, " +
//            "cm.tier, " +
//            "CASE " +
//            "WHEN cm.id IN (SELECT module_id FROM accessible_modules) THEN TRUE " +
//            "ELSE FALSE " +
//            "END AS is_accessible " +
//            "FROM course_module cm " +
//            "WHERE cm.id IN ( " +
//            "SELECT c.module_id " +
//            "FROM batch_accessible_concepts bac " +
//            "JOIN concept c ON bac.concept_id = c.id " +
//            "WHERE bac.batch_id = :batchId)", nativeQuery = true)
//    List<Object[]> getModulesForBatch(@Param("batchId") Long batchId, @Param("userId") Long userId);
//
//    @Query(value = "SELECT " +
//            "cm.id AS module_id, " +
//            "cm.name AS module_name, " +
//            "cm.description AS module_description, " +
//            "cm.tier, " +
//            "c.id AS concept_id, " +
//            "c.title AS concept_title, " +
//            "c.thumbnail_file_name, " +
//            "c.video_file_name, " +
//            "c.supporting_document, " +
//            "c.video_type, " +
//            "CASE " +
//            "WHEN LOWER(c.video_type) = 'setup videos' THEN 'setup' " +
//            "ELSE 'transactional' " +
//            "END AS concept_category, " +
//            "CASE " +
//            "WHEN cm.id IN (SELECT module_id FROM accessible_modules) THEN TRUE " +
//            "ELSE FALSE " +
//            "END AS is_accessible " +
//            "FROM batch_concepts bac " +
//            "JOIN concept c ON bac.concept_id = c.id " +
//            "JOIN course_module cm ON cm.id = c.module_id " +
//            "WHERE bac.batch_id = :batchId", nativeQuery = true)
//    List<Object[]> getConceptsForBatch(@Param("batchId") Long batchId);


}

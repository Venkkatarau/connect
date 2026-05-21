package com.connectthrive.connectthrive.adminlatest.repository;

import com.connectthrive.connectthrive.adminlatest.entity.CourseModule;
import com.connectthrive.connectthrive.adminlatest.entity.Instance;
import com.connectthrive.connectthrive.adminlatest.model.ConceptModuleDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface InstanceRepository extends JpaRepository<Instance, Long> {

    @Query(value = "SELECT id AS id, link AS link, username AS username, password AS password FROM instance", nativeQuery = true)
    List<Instance> findAllInstanceDTOs();

}

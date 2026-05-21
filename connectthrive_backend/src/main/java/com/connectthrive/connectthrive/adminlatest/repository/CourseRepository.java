package com.connectthrive.connectthrive.adminlatest.repository;

import com.connectthrive.connectthrive.adminlatest.entity.Concept;
import com.connectthrive.connectthrive.adminlatest.entity.Course;
import com.connectthrive.connectthrive.adminlatest.model.GetBatch;
import com.connectthrive.connectthrive.adminlatest.model.GetCourseDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface CourseRepository extends JpaRepository<Course, Long> {

    @Query(value = "SELECT c.name, m.name FROM Course c JOIN c.modules m", nativeQuery = true)
    List<GetCourseDTO> findAllCourses();
}

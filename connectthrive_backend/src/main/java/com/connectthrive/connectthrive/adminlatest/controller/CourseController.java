package com.connectthrive.connectthrive.adminlatest.controller;

import com.connectthrive.connectthrive.adminlatest.entity.Course;
import com.connectthrive.connectthrive.adminlatest.model.GetBatch;
import com.connectthrive.connectthrive.adminlatest.model.GetCourseDTO;
import com.connectthrive.connectthrive.adminlatest.repository.CourseRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/admin/courses")
public class CourseController {
    @Autowired
    private CourseRepository repo;

    @PostMapping
    public Course add(@RequestBody Course c) {
        return repo.save(c);
    }

    @PutMapping("/{id}")
    public Course edit(@PathVariable Long id, @RequestBody Course c) {
        Course e = repo.findById(id).orElseThrow();
        e.setName(c.getName());
        return repo.save(e);
    }

    @GetMapping("/getAllCourses")
    public List<GetCourseDTO> get(){

        return repo.findAllCourses();
    }

}

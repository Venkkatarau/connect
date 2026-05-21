package com.connectthrive.connectthrive.adminlatest.controller;

import com.connectthrive.connectthrive.adminlatest.entity.CourseModule;
import com.connectthrive.connectthrive.adminlatest.entity.Instance;
import com.connectthrive.connectthrive.adminlatest.model.ConceptDTO;
import com.connectthrive.connectthrive.adminlatest.model.ConceptModuleDTO;
import com.connectthrive.connectthrive.adminlatest.model.GetBatch;
import com.connectthrive.connectthrive.adminlatest.model.ModuleDTO;
import com.connectthrive.connectthrive.adminlatest.repository.BatchRepository;
import com.connectthrive.connectthrive.adminlatest.repository.InstanceRepository;
import com.connectthrive.connectthrive.adminlatest.repository.ModuleRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v2")
public class InstanceController {
    @Autowired
    private InstanceRepository repo;

    @PostMapping("/admin/addInstance")
    public Instance add(@RequestBody Instance m) {
        return repo.save(m);
    }

    @PutMapping("/admin/instance/{id}")
    public ResponseEntity<Instance> edit(@PathVariable Long id, @RequestBody Instance m) {
      try {
          Instance e = repo.findById(id).orElseThrow();
          e.setLink(m.getLink());
          e.setUsername(m.getUsername());
          e.setPassword(m.getPassword());
          return ResponseEntity.ok(repo.save(e));
      } catch (RuntimeException e) {
        return ResponseEntity.notFound().build();
    }
    }

    @GetMapping("/admin/getAllInstances")
    public List<Instance> get(){

        return repo.findAllInstanceDTOs();
    }
}
package com.connectthrive.connectthrive.adminlatest.controller;

import com.connectthrive.connectthrive.adminlatest.entity.Batch;
import com.connectthrive.connectthrive.adminlatest.entity.Concept;
import com.connectthrive.connectthrive.adminlatest.entity.CourseModule;
import com.connectthrive.connectthrive.adminlatest.model.*;
import com.connectthrive.connectthrive.adminlatest.repository.BatchRepository;
import com.connectthrive.connectthrive.adminlatest.service.BatchService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/v1/admin")
public class BatchController {
    @Autowired
    private BatchRepository repo;

    @Autowired
    BatchService batchService;
    @PostMapping("/addBatch")
    public Batch add(@RequestBody Batch batch) {
        return repo.save(batch);
    }

    @PutMapping("/updateBatch/{id}")
    public ResponseEntity<Batch> edit(@PathVariable Long id, @RequestBody Batch m) {
        try {
            Batch e = repo.findById(id).orElseThrow();
            e.setName(m.getName());
            return ResponseEntity.ok(repo.save(e));
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/getAllBatches")
    public List<GetBatch> get(){

        return repo.findAllBatches();
    }


    @PostMapping("/{id}/concepts")
    public void assign(@PathVariable Long id, @RequestBody Set<Long> cids) {
        Batch b = repo.findById(id).orElseThrow();
        b.setAccessibleConcepts(new HashSet<>(cids.stream()
                .map(cid -> {
                    Concept c = new Concept(cid);
                    return c;
                }).toList()));
        repo.save(b);
    }

//    @GetMapping("/{id}/modules")
//    public List<ModuleDTO> modulesForBatch(@PathVariable Long id) {
//        Batch b = repo.findById(id).orElseThrow();
//        return b.getAccessibleConcepts().stream()
//                .collect(Collectors.groupingBy(Concept::getModule))
//                .entrySet().stream().map(e -> {
//                    CourseModule m = e.getKey();
//                    ModuleDTO dto = new ModuleDTO();
//                    dto.setId(m.getId());
//                    dto.setName(m.getName());
//                    dto.setTier(m.getTier());
//                    dto.setConcepts(e.getValue().stream().map(c -> {
//                        ConceptDTO cd = new ConceptDTO();
//                        cd.setId(c.getId());
//                        cd.setTitle(c.getTitle());
//                        cd.setVideoUrl(c.getVideoFileName());
//                        return cd;
//                    }).toList());
//                    return dto;
//                }).toList();
//    }

    @PostMapping("/assign-concepts")
    public ResponseEntity<String> assignConcepts(@RequestBody List<BatchConceptRequest> request) {
        for(BatchConceptRequest batchConceptRequest : request) {
            batchService.assignConceptsToBatch(batchConceptRequest.getBatchId(), batchConceptRequest.getConceptIds());
        }
        return ResponseEntity.ok("Concepts assigned to batch.");
    }

    @GetMapping("/{batchId}/modules")
    public ResponseEntity<List<ModuleDTO>> getModulesForBatch(@PathVariable Long batchId,@RequestParam Long userId) {
        List<ModuleDTO> response = batchService.getModulesForBatch(batchId,userId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/users/{userId}/modules")
    public ResponseEntity<List<ModuleDTO>> getModulesForUser(@PathVariable Long userId) {
        try {
            List<ModuleDTO> response = batchService.getModulesForUser(userId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException ex) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/deleteBatch/{id}")
    public ResponseEntity<String> deleteBatch(@PathVariable Long id) {
        try {
            batchService.deleteBatch(id);
            return ResponseEntity.ok("Batch deleted successfully");
        } catch (RuntimeException ex) {
            return ResponseEntity.notFound().build();
        }
    }

}

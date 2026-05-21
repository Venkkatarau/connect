package com.connectthrive.connectthrive.adminlatest.controller;

import com.connectthrive.connectthrive.adminlatest.entity.Batch;
import com.connectthrive.connectthrive.adminlatest.entity.CourseModule;
import com.connectthrive.connectthrive.adminlatest.model.*;
import com.connectthrive.connectthrive.adminlatest.repository.BatchRepository;
import com.connectthrive.connectthrive.adminlatest.repository.ModuleRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/v2")
public class ModuleController {
    @Autowired
    private ModuleRepository repo;
    @Autowired
    private BatchRepository batchRepository;
    @PostMapping("/admin/addModule")
    public CourseModule add(@RequestBody CourseModule m) {
        return repo.save(m);
    }

    @PutMapping("/admin/updateModule/{id}")
    public ResponseEntity<CourseModule> edit(@PathVariable Long id, @RequestBody CourseModule m) {
      try {
          CourseModule e = repo.findById(id).orElseThrow();
          e.setName(m.getName());
          e.setDescription(m.getDescription());
          e.setTier(m.getTier());
          return ResponseEntity.ok(repo.save(e));
      } catch (RuntimeException e) {
        return ResponseEntity.notFound().build();
    }
    }

    @GetMapping("/admin/getAllModules")
    public List<ConceptModuleDTO> get(){

        return repo.findAllModuleDTOs();
    }
    @GetMapping("/conceptsGroupByModule")
    public List<ModuleDTO> getConceptsGroupedByModule() {
        List<Object[]> dtos = repo.findAllWithConcepts();


        Map<String, ModuleDTO> grouped = new LinkedHashMap<>();
        Map<String, ConceptDTO> conceptMap = new LinkedHashMap<>();

        for (Object[] row : dtos) {
            String name = (String) row[0];
            Long id = (Long) row[1];
            String tier = (String) row[2];
            String title = (String) row[3];
            Long courseId = (Long) row[4];
            String videoFileName = (String) row[5];
            String supportingDocument = (String) row[6];
            String thumbinailFileName = (String) row[7];
            String videoType = (String) row[8];
            String description = (String) row[9];


            // Unique key per group
            String key = name + "|" + id + "|" + tier + "|" + description;

            ModuleDTO module = grouped.computeIfAbsent(key, k -> {
                ModuleDTO dto = new ModuleDTO();
                dto.setName(name);
                dto.setId(id);
                dto.setDescription(description);
                dto.setTier(tier);
                return dto;
            });
            List<GetBatch> batchList = batchRepository.findByConceptId(courseId);

            String conceptKey = key + "|" + videoFileName + "|" + title + "|" + courseId+ "|" + thumbinailFileName;
            ConceptDTO conceptDTO = conceptMap.computeIfAbsent(conceptKey, k -> {
                ConceptDTO dto = new ConceptDTO();
                dto.setVideoUrl(videoFileName);
                dto.setTitle(title);
                dto.setId(courseId);
                dto.setThumbnailFileName(thumbinailFileName);
                dto.setBatchList(batchList);
                if ("Setup Videos".equalsIgnoreCase(videoType)) {
                    module.getConcepts().add(dto); // Add only once
                } else {
                    module.getTransactionConcepts().add(dto); // Add only once

                }
                return dto;
            });

         ;
            if(supportingDocument!=null){
                conceptDTO.getSupportingDocuments().add(supportingDocument);
            }
        }

        return new ArrayList<>(grouped.values());

    }
//    @GetMapping("/getBatchConceptsBasedOnUserAccess")
//    public List<ModuleDTO> getModulesForBatch(@RequestParam("batchId") Long batchId,@RequestParam("userId") Long userId) {
//        List<Object[]> modulesData = repo.getModulesForBatch(batchId, userId);
//        List<Object[]> conceptsData = repo.getConceptsForBatch(batchId);
//
//        Map<Long, ModuleDTO> moduleDTOMap = new HashMap<>();
//
//        // Process modules data
//        for (Object[] module : modulesData) {
//            Long moduleId = (Long) module[0];
//            ModuleDTO moduleDTO = new ModuleDTO();
//            moduleDTO.setId(moduleId);
//            moduleDTO.setName((String) module[1]);
//            moduleDTO.setDescription((String) module[2]);
//            moduleDTO.setTier((String) module[3]);
//            moduleDTO.setAccessible((Boolean) module[4]);
//
//            moduleDTOMap.put(moduleId, moduleDTO);
//        }
//
//        // Process concepts data
//        for (Object[] concept : conceptsData) {
//            Long moduleId = (Long) concept[0];
//            ModuleDTO moduleDTO = moduleDTOMap.get(moduleId);
//            if (moduleDTO != null) {
//                ConceptDTO conceptDTO = new ConceptDTO();
//                conceptDTO.setId((Long) concept[4]);
//                conceptDTO.setTitle((String) concept[5]);
//                conceptDTO.setThumbnailFileName((String) concept[6]);
//                conceptDTO.setVideoUrl((String) concept[7]);
////                conceptDTO.setSupportingDocuments((String) concept[8]);
//                conceptDTO.setVideoType((String) concept[9]);
//
//                if ("setup".equalsIgnoreCase((String) concept[10])) {
//                    moduleDTO.addConcept(conceptDTO); // add to setup concepts
//                } else {
//                    moduleDTO.addTranasactionConcept(conceptDTO); // add to transactional concepts
//                }
//            }
//        }
//
//        return new ArrayList<>(moduleDTOMap.values());
//    }
}
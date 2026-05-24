package com.connectthrive.connectthrive.adminlatest.service;

import com.connectthrive.connectthrive.adminlatest.entity.Batch;
import com.connectthrive.connectthrive.adminlatest.entity.Concept;
import com.connectthrive.connectthrive.adminlatest.entity.CourseModule;
import com.connectthrive.connectthrive.adminlatest.entity.ModuleAccessRequest;
import com.connectthrive.connectthrive.adminlatest.model.ConceptDTO;
import com.connectthrive.connectthrive.adminlatest.model.ModuleDTO;
import com.connectthrive.connectthrive.adminlatest.repository.BatchRepository;
import com.connectthrive.connectthrive.adminlatest.repository.ConceptRepository;
import com.connectthrive.connectthrive.adminlatest.repository.ModuleAccessRequestRepository;
import com.connectthrive.connectthrive.adminlatest.repository.ModuleRepository;
import com.connectthrive.connectthrive.user.model.User;
import com.connectthrive.connectthrive.user.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.function.Predicate;
import java.util.stream.Collectors;

@Service
public class BatchService {

    @Autowired
    private BatchRepository batchRepository;

    @Autowired
    private ConceptRepository conceptRepository;

    @Autowired
    private ModuleAccessRequestRepository accessRepo;

    @Autowired
    private UserRepository userRepository;

    public void assignConceptsToBatch(Long batchId, List<Long> conceptIds) {
        Batch batch = batchRepository.findById(batchId)
                .orElseThrow(() -> new RuntimeException("Batch not found"));
        Set<Concept> getAccesssiable= batch.getAccessibleConcepts();

        List<Concept> concepts = conceptRepository.findAllById(conceptIds);

        getAccesssiable.addAll(concepts);
        batch.setAccessibleConcepts(getAccesssiable);
        batchRepository.save(batch);
    }

    public List<ModuleDTO> getModulesForBatch(Long batchId,Long userId) {
        Batch batch = batchRepository.findById(batchId).orElse(null);
        if (batch == null) {
            return new ArrayList<>();
        }

        return buildModuleResponses(batch.getAccessibleConcepts(), getAccessiblePaidModuleIds(userId));
    }

    public List<ModuleDTO> getModulesForUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Map<Long, Concept> conceptsById = new LinkedHashMap<>();
        for (Batch batch : user.getBatches()) {
            for (Concept concept : batch.getAccessibleConcepts()) {
                conceptsById.putIfAbsent(concept.getId(), concept);
            }
        }

        return buildModuleResponses(conceptsById.values(), getAccessiblePaidModuleIds(userId));
    }

    private Set<Long> getAccessiblePaidModuleIds(Long userId) {
        List<ModuleAccessRequest> approvedRequests = accessRepo.findByStudentId(userId).stream()
                .filter(ModuleAccessRequest::isApproved)
                .toList();

        return approvedRequests.stream()
                .map(req -> req.getModule().getId())
                .collect(Collectors.toSet());
    }

    private List<ModuleDTO> buildModuleResponses(Collection<Concept> concepts, Set<Long> accessiblePaidModuleIds) {
        // Group by CourseModule
        Map<CourseModule, List<Concept>> groupedByModule = concepts.stream()
                .collect(Collectors.groupingBy(Concept::getModule));

        List<ModuleDTO> moduleResponses = new ArrayList<>();

        for (Map.Entry<CourseModule, List<Concept>> entry : groupedByModule.entrySet()) {
            CourseModule module = entry.getKey();
            List<Concept> moduleConcepts = entry.getValue();

            boolean isFree = "free".equalsIgnoreCase(module.getTier());
            boolean isAccessible = isFree || accessiblePaidModuleIds.contains(module.getId());
            // Initialize ModuleDTO
            ModuleDTO cmr = new ModuleDTO();
            cmr.setId(module.getId());
            cmr.setName(module.getName());
            cmr.setDescription(module.getDescription());
            cmr.setTier(module.getTier());
            cmr.setAccessible(isAccessible);


            // Partition concepts into Setup and Transactional
            Map<Boolean, List<ConceptDTO>> partitionedConcepts = moduleConcepts.stream()
                    .map(c -> {
                        ConceptDTO conceptDTO = new ConceptDTO();
                        conceptDTO.setId(c.getId());
                        conceptDTO.setTitle(c.getTitle());
                        conceptDTO.setThumbnailFileName(c.getThumbnailFileName());
                        conceptDTO.setVideoUrl(c.getVideoFileName());
                        conceptDTO.setSupportingDocuments(c.getSupportingDocument());
                        conceptDTO.setVideoType(c.getVideoType());
                        return conceptDTO;
                    })
                    .collect(Collectors.partitioningBy(c -> "Setup Videos".equalsIgnoreCase(c.getVideoType())));

            cmr.setConcepts(partitionedConcepts.get(true));  // Setup Videos
            cmr.setTransactionConcepts(partitionedConcepts.get(false));  // Transactional Videos

            moduleResponses.add(cmr);
        }

        return moduleResponses;
    }

    @Transactional
    public void deleteBatch(Long batchId) {
        Batch batch = batchRepository.findById(batchId)
                .orElseThrow(() -> new RuntimeException("Batch not found"));

        List<User> users = userRepository.findAll();
        for (User user : users) {
            boolean primaryBatchMatch = user.getBatch() != null && batchId.equals(user.getBatch().getId());
            boolean assignedBatchMatch = user.getBatches().stream().anyMatch(assignedBatch -> batchId.equals(assignedBatch.getId()));

            if (!primaryBatchMatch && !assignedBatchMatch) {
                continue;
            }

            Set<Batch> remainingBatches = user.getBatches().stream()
                    .filter(assignedBatch -> !batchId.equals(assignedBatch.getId()))
                    .collect(Collectors.toCollection(LinkedHashSet::new));
            user.setBatches(remainingBatches);
            userRepository.save(user);
        }

        batch.getAccessibleConcepts().clear();
        batchRepository.save(batch);
        batchRepository.delete(batch);
    }


}

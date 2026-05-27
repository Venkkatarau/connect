package com.connectthrive.connectthrive.adminlatest.service;

import com.connectthrive.connectthrive.adminlatest.entity.Batch;
import com.connectthrive.connectthrive.adminlatest.entity.Concept;
import com.connectthrive.connectthrive.adminlatest.entity.CourseModule;
import com.connectthrive.connectthrive.adminlatest.entity.ModuleAccessRequest;
import com.connectthrive.connectthrive.adminlatest.model.ConceptDTO;
import com.connectthrive.connectthrive.adminlatest.model.GetBatch;
import com.connectthrive.connectthrive.adminlatest.model.ModuleDTO;
import com.connectthrive.connectthrive.adminlatest.repository.BatchRepository;
import com.connectthrive.connectthrive.adminlatest.repository.ConceptRepository;
import com.connectthrive.connectthrive.adminlatest.repository.ModuleAccessRequestRepository;
import com.connectthrive.connectthrive.user.model.User;
import com.connectthrive.connectthrive.user.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
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

        Map<Long, List<GetBatch>> batchListByConceptId = new LinkedHashMap<>();
        List<GetBatch> batchList = toBatchSummaries(List.of(batch));
        for (Concept concept : batch.getAccessibleConcepts()) {
            batchListByConceptId.put(concept.getId(), batchList);
        }

        return buildModuleResponses(batch.getAccessibleConcepts(), getAccessiblePaidModuleIds(userId), batchListByConceptId);
    }

    public List<ModuleDTO> getModulesForUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        List<Batch> sortedUserBatches = user.getBatches().stream()
            .sorted(Comparator.comparing(Batch::getId, Comparator.nullsLast(Long::compareTo)))
            .toList();

        Map<Long, Concept> conceptsById = new LinkedHashMap<>();
        Map<Long, LinkedHashMap<Long, Batch>> batchesByConceptId = new LinkedHashMap<>();
        for (Batch batch : sortedUserBatches) {
            for (Concept concept : batch.getAccessibleConcepts()) {
                conceptsById.putIfAbsent(concept.getId(), concept);
                batchesByConceptId
                        .computeIfAbsent(concept.getId(), ignored -> new LinkedHashMap<>())
                        .put(batch.getId(), batch);
            }
        }

        Map<Long, List<GetBatch>> batchListByConceptId = new LinkedHashMap<>();
        for (Map.Entry<Long, LinkedHashMap<Long, Batch>> entry : batchesByConceptId.entrySet()) {
            batchListByConceptId.put(entry.getKey(), toBatchSummaries(entry.getValue().values()));
        }

        return buildModuleResponses(conceptsById.values(), getAccessiblePaidModuleIds(userId), batchListByConceptId);
    }

    private Set<Long> getAccessiblePaidModuleIds(Long userId) {
        List<ModuleAccessRequest> approvedRequests = accessRepo.findByStudentId(userId).stream()
                .filter(ModuleAccessRequest::isApproved)
                .toList();

        return approvedRequests.stream()
                .map(req -> req.getModule().getId())
                .collect(Collectors.toSet());
    }

    private List<ModuleDTO> buildModuleResponses(Collection<Concept> concepts,
                                                 Set<Long> accessiblePaidModuleIds,
                                                 Map<Long, List<GetBatch>> batchListByConceptId) {
        // Group by CourseModule
        Map<CourseModule, List<Concept>> groupedByModule = concepts.stream()
                .collect(Collectors.groupingBy(Concept::getModule));

        List<ModuleDTO> moduleResponses = new ArrayList<>();

        List<Map.Entry<CourseModule, List<Concept>>> sortedEntries = groupedByModule.entrySet().stream()
            .sorted(Comparator.comparingLong((Map.Entry<CourseModule, List<Concept>> entry) -> latestConceptId(entry.getValue())).reversed())
            .toList();

        for (Map.Entry<CourseModule, List<Concept>> entry : sortedEntries) {
            CourseModule module = entry.getKey();
            List<Concept> moduleConcepts = entry.getValue().stream()
                .sorted(Comparator.comparing(Concept::getId, Comparator.nullsLast(Long::compareTo)).reversed())
                .toList();

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
                        conceptDTO.setBatchList(batchListByConceptId.getOrDefault(c.getId(), List.of()));
                        return conceptDTO;
                    })
                    .collect(Collectors.partitioningBy(c -> "Setup Videos".equalsIgnoreCase(c.getVideoType())));

            cmr.setConcepts(partitionedConcepts.get(true));  // Setup Videos
            cmr.setTransactionConcepts(partitionedConcepts.get(false));  // Transactional Videos

            moduleResponses.add(cmr);
        }

        return moduleResponses;
    }

    private long latestConceptId(Collection<Concept> concepts) {
        return concepts.stream()
                .map(Concept::getId)
                .filter(Objects::nonNull)
                .max(Long::compareTo)
                .orElse(Long.MIN_VALUE);
    }

    private List<GetBatch> toBatchSummaries(Collection<Batch> batches) {
        return batches.stream()
                .sorted(Comparator.comparing(Batch::getId, Comparator.nullsLast(Long::compareTo)))
                .map(batch -> new BatchSummary(batch.getId(), batch.getName()))
                .collect(Collectors.toList());
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

    private static class BatchSummary implements GetBatch {
        private final Long id;
        private final String name;

        private BatchSummary(Long id, String name) {
            this.id = id;
            this.name = name;
        }

        @Override
        public Long getId() {
            return id;
        }

        @Override
        public String getName() {
            return name;
        }
    }


}

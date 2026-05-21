package com.connectthrive.connectthrive.user.serivce;

import com.connectthrive.connectthrive.adminlatest.entity.Concept;
import com.connectthrive.connectthrive.adminlatest.entity.CourseModule;
import com.connectthrive.connectthrive.adminlatest.entity.ModuleAccessRequest;
import com.connectthrive.connectthrive.adminlatest.model.ConceptDTO;
import com.connectthrive.connectthrive.adminlatest.repository.ModuleAccessRequestRepository;
import com.connectthrive.connectthrive.adminlatest.repository.ModuleRepository;
import com.connectthrive.connectthrive.user.model.CourseModuleResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Set;
import java.util.function.Predicate;
import java.util.stream.Collectors;

@Service
public class ModuleQueryService {

    @Autowired
    private ModuleRepository moduleRepo;

    @Autowired
    private ModuleAccessRequestRepository accessRepo;

    public List<CourseModuleResponse> getModulesForUser(Long userId, Long courseId) {
        List<CourseModule> modules = moduleRepo.findByCourseId(courseId);
        List<ModuleAccessRequest> approvedRequests = accessRepo.findByStudentId(userId).stream()
                .filter(ModuleAccessRequest::isApproved)
                .toList();

        Set<Long> accessiblePaidModuleIds = approvedRequests.stream()
                .map(req -> req.getModule().getId())
                .collect(Collectors.toSet());

        return modules.stream().map(module -> {
            boolean isFree = "free".equalsIgnoreCase(module.getTier());
            boolean isAccessible = isFree || accessiblePaidModuleIds.contains(module.getId());

            CourseModuleResponse res = new CourseModuleResponse();
            res.setId(module.getId());
            res.setName(module.getName());
            res.setDescription(module.getDescription());
            res.setTier(module.getTier());
            res.setAccessible(isAccessible);


            List<ConceptDTO> conceptResponses = module.getConcepts().stream().filter(concept -> "Setup Videos".equalsIgnoreCase(concept.getVideoType())).map(c -> {
                ConceptDTO cr = new ConceptDTO();
                cr.setId(c.getId());
                cr.setTitle(c.getTitle());
                cr.setThumbnailFileName(c.getThumbnailFileName());
                cr.setVideoUrl(c.getVideoFileName());
                cr.setSupportingDocuments(c.getSupportingDocument());
                return cr;
            }).collect(Collectors.toList());

            res.setConcepts(conceptResponses);

            List<ConceptDTO> transactionalVideos = module.getConcepts().stream().filter(concept -> !"Setup Videos".equalsIgnoreCase(concept.getVideoType())).map(c -> {
                ConceptDTO cr = new ConceptDTO();
                cr.setId(c.getId());
                cr.setTitle(c.getTitle());
                cr.setThumbnailFileName(c.getThumbnailFileName());
                cr.setVideoUrl(c.getVideoFileName());
                cr.setSupportingDocuments(c.getSupportingDocument());
                return cr;
            }).collect(Collectors.toList());

            res.setTransactionConcepts(transactionalVideos);

            return res;
        }).collect(Collectors.toList());
    }
}

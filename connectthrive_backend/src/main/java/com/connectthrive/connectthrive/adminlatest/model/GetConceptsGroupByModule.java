package com.connectthrive.connectthrive.adminlatest.model;

import java.util.List;

public class GetConceptsGroupByModule {
    private Long id;
    private String name, tier;
    private List<ConceptDTO> concepts;

    public GetConceptsGroupByModule(Long id, String name, String tier, List<ConceptDTO> concepts) {
        this.id = id;
        this.name = name;
        this.tier = tier;
        this.concepts = concepts;
    }
}

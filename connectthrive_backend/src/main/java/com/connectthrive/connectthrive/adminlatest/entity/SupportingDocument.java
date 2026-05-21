package com.connectthrive.connectthrive.adminlatest.entity;

import jakarta.persistence.*;

@Entity
public class SupportingDocument {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String name;
    private String url;

    @ManyToOne
    @JoinColumn(name = "concept_id")
    private Concept concept;
}
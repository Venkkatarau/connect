package com.connectthrive.connectthrive.adminlatest.entity;

import jakarta.persistence.*;

import java.util.List;

@Entity
public class Concept {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String title;
    private String videoFileName;
    private String thumbnailFileName;
    private String videoType;
    @ManyToOne
    private CourseModule module;

    @ElementCollection
    private List<String> supportingDocument;

    public Concept(Long id) {
        this.id = id;
    }
    public Concept() {

    }


    public Concept( String title, String videoFileName, String thumbnailFileName,String videoType,CourseModule module,List<String> supportingDocument) {
        this.title = title;
        this.videoFileName = videoFileName;
        this.thumbnailFileName = thumbnailFileName;
        this.videoType = videoType;
        this.module = module;

        this.supportingDocument = supportingDocument;
    }

    public String getVideoType() {
        return videoType;
    }

    public void setVideoType(String videoType) {
        this.videoType = videoType;
    }

    public String getThumbnailFileName() {
        return thumbnailFileName;
    }

    public void setThumbnailFileName(String thumbnailFileName) {
        this.thumbnailFileName = thumbnailFileName;
    }

    public Long getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public String getVideoFileName() {
        return videoFileName;
    }

    public CourseModule getModule() {
        return module;
    }

    public List<String> getSupportingDocument() {
        return supportingDocument;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public void setVideoFileName(String videoFileName) {
        this.videoFileName = videoFileName;
    }

    public void setModule(CourseModule module) {
        this.module = module;
    }

    public void setSupportingDocument(List<String> supportingDocument) {
        this.supportingDocument = supportingDocument;
    }


}
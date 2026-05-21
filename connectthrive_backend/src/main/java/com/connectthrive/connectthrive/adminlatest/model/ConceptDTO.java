package com.connectthrive.connectthrive.adminlatest.model;


import com.connectthrive.connectthrive.adminlatest.entity.Batch;

import java.util.ArrayList;
import java.util.List;

public class ConceptDTO {
    private Long id;
    private String title, videoUrl;
    private String thumbnailFileName;
    private String videoType;
    private List<GetBatch> batchList;
    public String getThumbnailFileName() {
        return thumbnailFileName;
    }

    public void setThumbnailFileName(String thumbnailFileName) {
        this.thumbnailFileName = thumbnailFileName;
    }

    private List<String> supportingDocuments = new ArrayList<>();

    public List<String> getSupportingDocuments() {
        return supportingDocuments;
    }

    public void setSupportingDocuments(List<String> supportingDocuments) {
        this.supportingDocuments = supportingDocuments;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getVideoUrl() {
        return videoUrl;
    }

    public void setVideoUrl(String videoUrl) {
        this.videoUrl = videoUrl;
    }

    public List<GetBatch> getBatchList() {
        return batchList;
    }

    public void setBatchList(List<GetBatch> batchList) {
        this.batchList = batchList;
    }

    public String getVideoType() {
        return videoType;
    }

    public void setVideoType(String videoType) {
        this.videoType = videoType;
    }
}
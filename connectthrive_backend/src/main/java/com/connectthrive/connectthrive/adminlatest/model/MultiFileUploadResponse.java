package com.connectthrive.connectthrive.adminlatest.model;

import java.util.List;

public class MultiFileUploadResponse {

    private boolean status;
    private String message;

    private String videoFileName;
    List<String> uploadedFileNames;


    public MultiFileUploadResponse(boolean status, String message, String videoFileName, List<String> uploadedFileNames) {
        this.status = status;
        this.message = message;
        this.videoFileName = videoFileName;
        this.uploadedFileNames = uploadedFileNames;
    }

    public boolean isStatus() {
        return status;
    }

    public void setStatus(boolean status) {
        this.status = status;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public List<String> getUploadedFileNames() {
        return uploadedFileNames;
    }

    public void setUploadedFileNames(List<String> uploadedFileNames) {
        this.uploadedFileNames = uploadedFileNames;
    }

    public String getVideoFileName() {
        return videoFileName;
    }

    public void setVideoFileName(String videoFileName) {
        this.videoFileName = videoFileName;
    }
}

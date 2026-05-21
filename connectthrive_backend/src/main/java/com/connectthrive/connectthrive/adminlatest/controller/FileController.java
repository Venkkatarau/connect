package com.connectthrive.connectthrive.adminlatest.controller;

import com.connectthrive.connectthrive.adminlatest.model.MultiFileUploadResponse;
import com.connectthrive.connectthrive.adminlatest.service.ConceptService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/v2")
public class FileController {

@Autowired
private ConceptService s3Service;
    @Value("${aws.bucketName}")
    private String bucketName;
    @Autowired
    private S3Client s3Client;
    @PostMapping(
            value = "/admin/upload/supportingDocuments",
            produces = MediaType.APPLICATION_JSON_VALUE,
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<MultiFileUploadResponse> uploadFiles(@RequestParam("files") List<MultipartFile> files,
                                                               @RequestParam("thubminalFile") MultipartFile multipartFile,
                                                               @RequestParam("title") String title,
                                                               @RequestParam("moduleId") Long moduleId,
                                                               @RequestParam("batchId") Long batchId,
                                                               @RequestParam("videoType") String videoType) {
        try {
           return ResponseEntity.ok(s3Service.uploadFiles(files,multipartFile,title,moduleId,batchId,videoType));
        } catch (IOException e) {
            System.out.println("IOException is::"+e.getMessage());

            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MultiFileUploadResponse(false,"Error uploading files: " + e.getMessage(),null,null));
        } catch (InterruptedException e) {
            System.out.println("InterruptedException is::"+e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MultiFileUploadResponse(false,"Error uploading files: " + e.getMessage(),null,null));

        }
    }

    @GetMapping("/user/view/supportingDocuments")
    public ResponseEntity<byte[]> viewFile(@RequestParam String filename) {
        try {
            byte[] fileContent = s3Service.downloadFile(filename);
            String contentType = s3Service.getContentType(filename); // Optional if you want to return correct MIME

            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + filename + "\"")
                    .contentType(MediaType.parseMediaType(contentType))
                    .body(fileContent);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(null);
        }
    }

    @GetMapping("/getThumbnail")
    public ResponseEntity<byte[]> getThumbnail(@RequestParam String key) {
        try {
            GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .build();

            ResponseBytes<GetObjectResponse> objectBytes = s3Client.getObjectAsBytes(getObjectRequest);

            return ResponseEntity.ok()
                    .contentType(MediaType.IMAGE_JPEG)
                    .body(objectBytes.asByteArray());

        } catch (NoSuchKeyException e) {
            System.out.println("Thumbnail not found in S3 for key: " + key + ". Returning default fallback placeholder.");
            byte[] fallbackPng = java.util.Base64.getDecoder().decode(
                "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAD0lEQVR4nGO4jAMwDC0JANVbnkEAmWaQAAAAAElFTkSuQmCC"
            );
            return ResponseEntity.ok()
                    .contentType(MediaType.IMAGE_PNG)
                    .body(fallbackPng);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

}

package com.connectthrive.connectthrive.adminlatest.service;

import com.connectthrive.connectthrive.adminlatest.entity.Concept;
import com.connectthrive.connectthrive.adminlatest.entity.CourseModule;
import com.connectthrive.connectthrive.adminlatest.model.MultiFileUploadResponse;
import com.connectthrive.connectthrive.adminlatest.repository.ConceptRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.ResponseInputStream;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;

import java.io.*;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class ConceptService {
    @Autowired
    private ConceptRepository repo;
    @Autowired
    private S3Client s3Client;
    @Value("${aws.bucketName}")
    private String bucketName;

    @Autowired
    BatchService batchService;
    @Autowired
    ThumbnailService thumbnailService;
    public MultiFileUploadResponse uploadFiles(List<MultipartFile> files,MultipartFile multipartFile,String title, Long moduleId,Long batchId,String videoType) throws IOException, InterruptedException {
        List<String> uploadFileName = new ArrayList<>();
        String videoFileName=null;
        String thumbnailFileName=uploadThumbnail(multipartFile,moduleId);;
        String key=null;
        for (MultipartFile file : files) {
            String sanitizedName = sanitizeFilename(file.getOriginalFilename());
            if(file.getOriginalFilename().toLowerCase().contains("mp4")){
                key = moduleId+"/"+"mp4/"+UUID.randomUUID()+"_"+sanitizedName;
                videoFileName = key;
                String videoFile = multipartUpload(bucketName,key,file.getInputStream(),file.getSize(),file.getContentType());
                System.out.println("videoFile :"+videoFile);
            }else{
                key = moduleId+"/"+"supportingDocs/"+UUID.randomUUID()+"_"+sanitizedName;
                uploadFileName.add(key);
                PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                        .bucket(bucketName)
                        .key(key)
                        .contentType(file.getContentType())
                        .build();

                s3Client.putObject(putObjectRequest,
                        RequestBody.fromInputStream(file.getInputStream(), file.getSize()));
            }


        }
       CourseModule module = new CourseModule();
        module.setId(moduleId);

        Concept concept = new Concept(title,videoFileName,thumbnailFileName,videoType,module,uploadFileName);
        Concept concept1 = repo.save(concept);
        System.out.println("concept id is :"+concept1.getId());
        List<Long> conceptList = new ArrayList<>();
        conceptList.add(concept1.getId());
        batchService.assignConceptsToBatch(batchId,conceptList);
        return new MultiFileUploadResponse(true,"Files uploaded successfully!",videoFileName,uploadFileName);
    }

    public byte[] downloadFile(String filename) {
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(filename)
                .build();

        try (ResponseInputStream<GetObjectResponse> response = s3Client.getObject(getObjectRequest)) {
            return response.readAllBytes();
        } catch (IOException e) {
            throw new RuntimeException("Error reading file from S3", e);
        }
    }

    public String getContentType(String filename) {
        HeadObjectRequest headObjectRequest = HeadObjectRequest.builder()
                .bucket(bucketName)
                .key(filename)
                .build();

        HeadObjectResponse response = s3Client.headObject(headObjectRequest);
        return response.contentType();
    }

    public String uploadThumbnail(MultipartFile thumbnailFile,Long moduleId) throws IOException {
        String sanitizedName = sanitizeFilename(thumbnailFile.getOriginalFilename());
        String key =  moduleId+"/"+"thumbnails/"+UUID.randomUUID() + "_" + sanitizedName;
        PutObjectRequest request = PutObjectRequest.builder()
                .bucket(bucketName)
                .key( key)
                .contentType(thumbnailFile.getContentType())
                .build();
        s3Client.putObject(request,
                RequestBody.fromInputStream(thumbnailFile.getInputStream(), thumbnailFile.getSize()));


        System.out.println("thumbnail::" + key);
        return key;
    }

    public String multipartUpload(String bucketName, String key, InputStream inputStream, long contentLength, String contentType) throws IOException {
        CreateMultipartUploadRequest createMultipartUploadRequest = CreateMultipartUploadRequest.builder()
                .bucket(bucketName)
                .key(key)
                .contentType(contentType)
                .build();

        CreateMultipartUploadResponse response = s3Client.createMultipartUpload(createMultipartUploadRequest);
        String uploadId = response.uploadId();

        List<CompletedPart> completedParts = new ArrayList<>();
        final long partSize = 5 * 1024 * 1024; // 5MB per part

        try {
            long bytesUploaded = 0;
            int partNumber = 1;
            byte[] buffer = new byte[(int) partSize];

            while (bytesUploaded < contentLength) {
                int bytesToRead = (int) Math.min(partSize, contentLength - bytesUploaded);
                int read = inputStream.read(buffer, 0, bytesToRead);
                if (read <= 0) break;

                UploadPartRequest uploadPartRequest = UploadPartRequest.builder()
                        .bucket(bucketName)
                        .key(key)
                        .uploadId(uploadId)
                        .partNumber(partNumber)
                        .contentLength((long) read)
                        .build();

                byte[] actualBytes = (read == partSize) ? buffer : java.util.Arrays.copyOf(buffer, read);

                UploadPartResponse uploadPartResponse = s3Client.uploadPart(uploadPartRequest,
                        RequestBody.fromBytes(actualBytes));

                completedParts.add(CompletedPart.builder()
                        .partNumber(partNumber)
                        .eTag(uploadPartResponse.eTag())
                        .build());

                bytesUploaded += read;
                partNumber++;
            }

            CompleteMultipartUploadRequest completeMultipartUploadRequest = CompleteMultipartUploadRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .uploadId(uploadId)
                    .multipartUpload(CompletedMultipartUpload.builder()
                            .parts(completedParts)
                            .build())
                    .build();

            CompleteMultipartUploadResponse completeResponse = s3Client.completeMultipartUpload(completeMultipartUploadRequest);
            return completeResponse.location();

        } catch (Exception e) {
            // Abort upload if something goes wrong
            s3Client.abortMultipartUpload(AbortMultipartUploadRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .uploadId(uploadId)
                    .build());
            throw new RuntimeException("Multipart upload failed: " + e.getMessage(), e);
        } finally {
            inputStream.close();
        }
    }

    private String sanitizeFilename(String filename) {
        if (filename == null) return "file";
        return filename.replaceAll("[^\\x00-\\x7F]", "").replaceAll("\\s+", "_");
    }
}

//package com.connectthrive.connectthrive.video;
//
//import jakarta.servlet.ServletOutputStream;
//import jakarta.servlet.http.HttpServletRequest;
//import jakarta.servlet.http.HttpServletResponse;
//import org.springframework.beans.factory.annotation.Value;
//import org.springframework.http.ResponseEntity;
//import org.springframework.web.bind.annotation.*;
//import org.springframework.web.multipart.MultipartFile;
//import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
//import software.amazon.awssdk.auth.credentials.ProfileCredentialsProvider;
//import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
//import software.amazon.awssdk.core.ResponseInputStream;
//import software.amazon.awssdk.core.sync.RequestBody;
//import software.amazon.awssdk.regions.Region;
//import software.amazon.awssdk.services.s3.S3Client;
//import software.amazon.awssdk.services.s3.model.*;
//
//import java.io.IOException;
//
//import org.springframework.core.io.buffer.DataBuffer;
//import org.springframework.core.io.buffer.DataBufferUtils;
//import org.springframework.core.io.buffer.DefaultDataBufferFactory;
//import org.springframework.http.MediaType;
//import org.springframework.http.ResponseEntity;
//import org.springframework.web.bind.annotation.*;
//import reactor.core.publisher.Flux;
//import reactor.core.publisher.Mono;
//import software.amazon.awssdk.core.ResponseInputStream;
//import software.amazon.awssdk.services.s3.S3Client;
//import software.amazon.awssdk.services.s3.model.GetObjectRequest;
//import software.amazon.awssdk.services.s3.presigner.S3Presigner;
//import org.springframework.web.bind.annotation.*;
//import software.amazon.awssdk.auth.credentials.ProfileCredentialsProvider;
//import software.amazon.awssdk.regions.Region;
//import software.amazon.awssdk.services.s3.model.GetObjectRequest;
//import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
////import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
//
//import java.net.URL;
//import java.time.Duration;
//@RestController
//@RequestMapping("/video")
//public class VideoController {
//
//    private final S3Client s3Client;
//    private final String bucket;
//    private final S3Presigner presigner;
//
//
//
//    public VideoController(S3Client s3Client, @Value("${aws.s3.bucket-name}") String bucket,     @Value("${aws.access-key-id}")
//     String accessKey,
//
//    @Value("${aws.secret-access-key}")
//     String secretKey,
//
//    @Value("${aws.region}")
//     String region) {
//        AwsBasicCredentials credentials = AwsBasicCredentials.create(accessKey, secretKey);
//
//        this.s3Client = s3Client;
//        this.bucket = bucket;
//        this.presigner = S3Presigner.builder()
//                .region(Region.US_EAST_1) // Replace with your region
//                .credentialsProvider(StaticCredentialsProvider.create(credentials)) // Or use DefaultCredentialsProvider
//                .build();
//
//    }
//
//    @PostMapping("/upload")
//    public ResponseEntity<String> uploadVideo(@RequestParam("file") MultipartFile file) throws IOException {
//        //String key = "videos/" + file.getOriginalFilename();
//        String key = file.getOriginalFilename();
//
//        PutObjectRequest putRequest = PutObjectRequest.builder()
//                .bucket(bucket)
//                .key(key)
//                .contentType(file.getContentType())
//                .build();
//
//        s3Client.putObject(putRequest, RequestBody.fromInputStream(file.getInputStream(), file.getSize()));
//
//        return ResponseEntity.ok("Uploaded to S3 with key: " + key);
//    }
////Generate a temporary, signed URL for a video file in a private S3 bucket.
//    @GetMapping("/signed-url/{filename}")
//    public String generatePresignedVideoUrl(@PathVariable String filename) {
//        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
//                .bucket(bucket)
//                .key(filename)
//                .build();
//
//        GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
//                .signatureDuration(Duration.ofMinutes(10)) // URL valid for 10 minutes
//                .getObjectRequest(getObjectRequest)
//                .build();
//
//        URL presignedUrl = presigner.presignGetObject(presignRequest).url();
//        return presignedUrl.toString();
//    }
////not working
////    @GetMapping(value = "/stream/{filename}", produces = MediaType.APPLICATION_OCTET_STREAM_VALUE)
////    public Mono<ResponseEntity<Flux<DataBuffer>>> streamVideo(@PathVariable String filename) {
////        try {
////            // Create S3 GetObjectRequest
////            GetObjectRequest getObjectRequest = GetObjectRequest.builder()
////                    .bucket(bucket)
////                    .key(filename)
////                    .build();
////
////            // Get the S3 object as an input stream
////            ResponseInputStream<?> s3InputStream = s3Client.getObject(getObjectRequest);
////
////            // Wrap the input stream as a reactive Flux<DataBuffer>
////            Flux<DataBuffer> body = DataBufferUtils.readInputStream(
////                    () -> s3InputStream,
////                    new DefaultDataBufferFactory(),
////                    8192 // buffer size
////            );
////
////            // Return a 200 OK response with stream body
////            return Mono.just(
////                    ResponseEntity.ok()
////                            .contentType(MediaType.APPLICATION_OCTET_STREAM)
////                            .header("Content-Disposition", "inline; filename=\"" + filename + "\"")
////                            .body(body)
////            );
////
////        } catch (Exception e) {
////            return Mono.error(new RuntimeException("Failed to stream video", e));
////        }
////    }
//
////    @GetMapping("/stream/{filename}")
////    public void streamVideo(@PathVariable String filename, HttpServletRequest request, HttpServletResponse response) {
////       // String key = "videos/" + filename;
////        String key = filename;
////
////        try {
////            // Get object metadata to determine file size
////            HeadObjectRequest headRequest = HeadObjectRequest.builder()
////                    .bucket(bucket)
////                    .key(key)
////                    .build();
////            HeadObjectResponse objectMetadata = s3Client.headObject(headRequest);
////            long fileSize = objectMetadata.contentLength();
////
////            // Check for Range header
////            String rangeHeader = request.getHeader("Range");
////            long start = 0, end = fileSize - 1;
////
////            if (rangeHeader != null && rangeHeader.startsWith("bytes=")) {
////                String[] ranges = rangeHeader.substring(6).split("-");
////                start = Long.parseLong(ranges[0]);
////                if (ranges.length > 1 && !ranges[1].isEmpty()) {
////                    end = Long.parseLong(ranges[1]);
////                }
////            }
////
////            long contentLength = end - start + 1;
////
////            // Build GetObjectRequest with Range
////            GetObjectRequest getObjectRequest = GetObjectRequest.builder()
////                    .bucket(bucket)
////                    .key(key)
////                    .range("bytes=" + start + "-" + end)
////                    .build();
////
////            try (ResponseInputStream<GetObjectResponse> s3Stream = s3Client.getObject(getObjectRequest);
////                 ServletOutputStream outputStream = response.getOutputStream()) {
////
////                response.setStatus(rangeHeader == null ? 200 : 206);
////                response.setContentType("video/mp4");
////                response.setHeader("Content-Disposition", "inline; filename=\"" + filename + "\"");
////                response.setHeader("Accept-Ranges", "bytes");
////                response.setHeader("Content-Length", String.valueOf(contentLength));
////                response.setHeader("Content-Range", "bytes " + start + "-" + end + "/" + fileSize);
////
////                byte[] buffer = new byte[8192];
////                int bytesRead;
////                while ((bytesRead = s3Stream.read(buffer)) != -1) {
////                    outputStream.write(buffer, 0, bytesRead);
////                }
////                outputStream.flush();
////            }
////
////        } catch (Exception e) {
////            throw new RuntimeException("Error while streaming video", e);
////        }
////    }
//
//
////    @GetMapping("/stream/{filename}")
////    public void streamVideo(@PathVariable String filename, HttpServletResponse response) {
////        //String key = "videos/" + filename;
////        String key = filename;
////
////        GetObjectRequest getRequest = GetObjectRequest.builder()
////                .bucket(bucket)
////                .key(key)
////                .build();
////
////        try (ResponseInputStream<GetObjectResponse> s3Object = s3Client.getObject(getRequest);
////             ServletOutputStream outputStream = response.getOutputStream()) {
////
////            response.setContentType("video/mp4");
////            response.setHeader("Content-Disposition", "inline; filename=\"" + filename + "\"");
////
////            byte[] buffer = new byte[8192];
////            int bytesRead;
////            while ((bytesRead = s3Object.read(buffer)) != -1) {
////                outputStream.write(buffer, 0, bytesRead);
////            }
////            outputStream.flush();
////        } catch (IOException e) {
////            throw new RuntimeException("Streaming failed: " + e.getMessage(), e);
////        }
////    }
//
//}

package com.connectthrive.connectthrive.adminlatest.service;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.*;
import java.util.UUID;

@Service
public class ThumbnailService {

    public File generateThumbnail(MultipartFile videoFile) throws IOException, InterruptedException {
        // Step 1: Create a temp file
        File tempVideoFile = File.createTempFile("temp_video_", ".mp4");

        // Step 2: Write MultipartFile content manually to disk
        try (InputStream in = videoFile.getInputStream();
             OutputStream out = new FileOutputStream(tempVideoFile)) {
            byte[] buffer = new byte[8192];
            int bytesRead;
            while ((bytesRead = in.read(buffer)) != -1) {
                out.write(buffer, 0, bytesRead);
            }
        }

        // Step 3: Create a thumbnail output file
        String thumbnailName = UUID.randomUUID() + "_thumb.jpg";
        File thumbnail = new File(System.getProperty("java.io.tmpdir"), thumbnailName);

        // Step 4: Use FFmpeg to extract thumbnail
        ProcessBuilder pb = new ProcessBuilder(
                "ffmpeg", "-y", "-i", tempVideoFile.getAbsolutePath(),
                "-ss", "00:00:01", "-vframes", "1",
                thumbnail.getAbsolutePath()
        );
        pb.redirectErrorStream(true);
        Process process = pb.start();

        // Optional: log FFmpeg output for debugging
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println(line);
            }
        }

        int exitCode = process.waitFor();
        if (exitCode != 0 || !thumbnail.exists()) {
            throw new RuntimeException("FFmpeg failed to generate thumbnail.");
        }

        // Step 5: Cleanup
        tempVideoFile.delete();

        return thumbnail;
    }


}
package com.connectthrive.connectthrive.user.serivce;

import com.connectthrive.connectthrive.config.SMSConfig;
import com.connectthrive.connectthrive.user.model.OtpVerification;
import com.connectthrive.connectthrive.user.repository.OtpRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sns.model.MessageAttributeValue;
import software.amazon.awssdk.services.sns.model.PublishRequest;
import software.amazon.awssdk.services.sns.model.PublishResponse;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Random;
@Transactional
@Service
public class OtpService {
    @Autowired
    private SnsClient snsClient;

    @Autowired
    private OtpRepository otpRepository;

    // India DLT Registration Details
    private static final String DLT_ENTITY_ID = "1001901773386707144";
    private static final String DLT_TEMPLATE_ID = "1007173300907696138";
    private static final String SENDER_ID = "CTTORA";

    public String generateOtp() {
        return String.valueOf(new Random().nextInt(8999) + 1000);
    }

    private String sendOtp(String mobileNumber, String otp) {
        System.out.println("Sending OTP to your mobile number: " + mobileNumber + " - OTP: " + otp);
        // Message MUST match the registered DLT template exactly
        String message = otp + " is your OTP for ConnectThrive verification. It is valid for 5 minutes.";

        // DLT compliance attributes required for India SMS
        Map<String, MessageAttributeValue> smsAttributes = new HashMap<>();
        smsAttributes.put("AWS.MM.SMS.EntityId", MessageAttributeValue.builder()
                .stringValue(DLT_ENTITY_ID).dataType("String").build());
        smsAttributes.put("AWS.MM.SMS.TemplateId", MessageAttributeValue.builder()
                .stringValue(DLT_TEMPLATE_ID).dataType("String").build());
        smsAttributes.put("AWS.SNS.SMS.SenderID", MessageAttributeValue.builder()
                .stringValue(SENDER_ID).dataType("String").build());
        smsAttributes.put("AWS.SNS.SMS.SMSType", MessageAttributeValue.builder()
                .stringValue("Transactional").dataType("String").build());

        PublishRequest request = PublishRequest.builder()
                .message(message)
                .phoneNumber("+91"+mobileNumber) // E.164 format: +919876543210
                .messageAttributes(smsAttributes)
                .build();
    try{
        PublishResponse result = snsClient.publish(request);
        System.out.println("MessageId: " + result.messageId());
        return ("Success:"+result.messageId());
    } catch (Exception e) {
        System.out.println("Exception");
        e.printStackTrace();
        return e.getMessage();
    }
    }

    public String createOtp(String mobileNumber) {

        if(otpRepository.findByMobileNumber(mobileNumber).isPresent()){
            otpRepository.deleteByMobileNumber(mobileNumber);
        }
        String otp = generateOtp();
        OtpVerification otpRecord = new OtpVerification();
        otpRecord.setMobileNumber(mobileNumber);
        otpRecord.setOtp(otp);
        otpRecord.setExpiryTime(LocalDateTime.now().plusMinutes(5));
        otpRepository.save(otpRecord);
       return sendOtp(mobileNumber, otp);
    }

    public boolean verifyOtp(String mobileNumber, String otp) {
        Optional<OtpVerification> record = otpRepository.findByMobileNumber(mobileNumber);
        return record.isPresent() &&
                record.get().getOtp().equals(otp) &&
                record.get().getExpiryTime().isAfter(LocalDateTime.now());
    }
}


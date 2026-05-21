package com.connectthrive.connectthrive.user.repository;

import com.connectthrive.connectthrive.user.model.OtpVerification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OtpRepository extends JpaRepository<OtpVerification, Long> {
    Optional<OtpVerification> findByMobileNumber(String mobileNumber);
    @Query("SELECT o FROM OtpVerification o WHERE o.mobileNumber = :mobileNumber ORDER BY o.expiryTime DESC")
    OtpVerification findTopByMobileNumberOrderByExpiryTimeDesc(@Param("mobileNumber") String mobileNumber);
    void deleteByMobileNumber(String mobileNumber);

}
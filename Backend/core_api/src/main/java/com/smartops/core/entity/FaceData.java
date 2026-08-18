package com.smartops.core.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

/**
 * Entity đại diện cho Dữ liệu khuôn mặt (FaceData)
 */
@Entity
@Table(name = "face_data")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FaceData {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Liên kết 1-1 với User
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // Vector 128 chiều đại diện cho khuôn mặt
    @Column(name = "face_vector")
    private double[] faceVector;

    @Column(name = "id_card_url")
    private String idCardUrl;

    @Column(name = "selfie_url")
    private String selfieUrl;

    @Column(name = "id_number")
    private String idNumber;

    @Column(name = "full_name_on_id")
    private String fullNameOnId;

    @Column(name = "ekyc_similarity")
    private Double ekycSimilarity;

    @Column(name = "last_updated")
    private LocalDateTime lastUpdated;

    @PrePersist
    @PreUpdate
    protected void onUpdate() {
        lastUpdated = LocalDateTime.now();
    }
}

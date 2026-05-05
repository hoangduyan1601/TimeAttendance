package com.smartops.core.service;

import org.springframework.web.multipart.MultipartFile;

public interface EkycService {
    void registerEkyc(Long userId, MultipartFile selfieImage);

    /**
     * eKYC nâng cao: gửi kèm CCCD + selfie để AI so khớp và trích vector.
     * Nếu idCardImage = null, service có thể fallback về luồng selfie-only.
     */
    void registerEkyc(Long userId, MultipartFile idCardImage, MultipartFile selfieImage);
}

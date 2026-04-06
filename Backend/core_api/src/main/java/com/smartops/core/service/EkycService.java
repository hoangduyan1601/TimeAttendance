package com.smartops.core.service;

import org.springframework.web.multipart.MultipartFile;

public interface EkycService {
    void registerEkyc(Long userId, MultipartFile idCardImage, MultipartFile selfieImage);
}

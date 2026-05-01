package com.smartops.core.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;
import java.nio.file.Paths;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${upload.path}")
    private String uploadPath;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        Path path = Paths.get("uploads").toAbsolutePath();
        String uploadResourcePath = "file:" + path.toString() + "/";
        
        // Hỗ trợ cả 2 định dạng đường dẫn
        registry.addResourceHandler("/uploads/**", "/api/v1/uploads/**")
                .addResourceLocations(uploadResourcePath);
    }

    @Override
    public void addCorsMappings(org.springframework.web.servlet.config.annotation.CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins("*") // Cho phép tất cả các nguồn (phù hợp cho môi trường dev)
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*");
    }
}

package com.flashcard.controller;

import com.flashcard.dto.ApiResponse;
import com.flashcard.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/health")
@RequiredArgsConstructor
public class HealthController {

    private final UserRepository userRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> checkHealth() {
        Map<String, Object> status = new HashMap<>();
        status.put("system", "Flashcard Learning API");
        status.put("version", "0.1.0");
        status.put("status", "UP");

        try {
            // Kiểm tra kết nối tới PostgreSQL bằng cách đếm số user
            long userCount = userRepository.count();
            status.put("database", "CONNECTED");
            status.put("totalUsersInDb", userCount);
        } catch (Exception e) {
            status.put("database", "DISCONNECTED: " + e.getMessage());
            return ResponseEntity.status(500).body(ApiResponse.error("Không thể kết nối cơ sở dữ liệu PostgreSQL"));
        }

        return ResponseEntity.ok(ApiResponse.ok(status, "Hệ thống Backend Spring Boot và PostgreSQL hoạt động bình thường!"));
    }
}

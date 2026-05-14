package com.cw.rd.dto.notification;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class NotificationResponse {
    private Long id;
    private String text;
    private Boolean read;
    private Long ticketId;
    private Long messageId;
    private LocalDateTime createdAt;
}

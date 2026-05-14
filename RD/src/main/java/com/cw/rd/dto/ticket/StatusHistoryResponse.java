package com.cw.rd.dto.ticket;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class StatusHistoryResponse {
    private String status;
    private String changedBy;
    private String description;
    private LocalDateTime updatedAt;
}

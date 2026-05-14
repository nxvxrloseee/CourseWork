package com.cw.rd.dto.ticket;

import com.cw.rd.dto.ticket.TicketServiceResponse;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class TicketResponse {
    private Long id;
    private String title;
    private String description;
    private String category;
    private String status;
    private Long customerId;
    private String customerName;
    private Long masterId;
    private String masterName;
    private LocalDateTime selectedDatetime;
    private LocalDateTime createdAt;
    private LocalDateTime pricesConfirmedAt;
    private List<String> mediaUrls;
    private List<TicketServiceResponse> services;
    private BigDecimal totalPrice;
}

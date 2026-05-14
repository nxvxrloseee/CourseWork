package com.cw.rd.dto.ticket;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class TicketServiceResponse {
    private Long id;
    private Long serviceId;
    private String serviceName;
    private BigDecimal price;
    private Integer quantity;
    private BigDecimal subtotal;
}

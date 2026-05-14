package com.cw.rd.dto.service;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class ServiceResponse {
    private Long id;
    private String name;
    private String description;
    private BigDecimal price;
    private Boolean isActive;
}

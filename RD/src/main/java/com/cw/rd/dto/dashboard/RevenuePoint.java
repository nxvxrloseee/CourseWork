package com.cw.rd.dto.dashboard;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RevenuePoint {
    private LocalDate date;
    private BigDecimal revenue;
    private long completed;
}

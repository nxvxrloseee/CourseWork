package com.cw.rd.dto.ticket;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UpdateTicketServiceRequest {

    @NotNull
    @Min(1)
    @Max(999)
    private Integer quantity;
}

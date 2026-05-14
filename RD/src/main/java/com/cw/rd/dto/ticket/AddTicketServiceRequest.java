package com.cw.rd.dto.ticket;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class AddTicketServiceRequest {

    @NotNull
    private Long serviceId;

    @NotNull
    @Min(1)
    private Integer quantity;
}

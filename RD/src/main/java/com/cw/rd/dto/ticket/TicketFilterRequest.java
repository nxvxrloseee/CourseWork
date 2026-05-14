package com.cw.rd.dto.ticket;

import lombok.Data;

@Data
public class TicketFilterRequest {
    private Long categoryId;
    private String status;
    private String search;
    /** createdAtDesc | createdAtAsc | idDesc | idAsc | scheduledDesc | scheduledAsc | statusAsc | statusDesc */
    private String sort;
    private Boolean excludeCompleted;
}

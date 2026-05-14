package com.cw.rd.dto.dashboard;

import lombok.Data;

@Data
public class DashboardResponse {
    private long totalNew;
    private long totalInProgress;
    private long totalCompleted;
    private long totalCancelled;
}

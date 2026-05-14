package com.cw.rd.controller;

import com.cw.rd.dto.dashboard.DashboardResponse;
import com.cw.rd.dto.dashboard.RevenuePoint;
import com.cw.rd.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping
    @PreAuthorize("hasRole('MASTER')")
    public ResponseEntity<DashboardResponse> getDashboard(Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(dashboardService.getDashboard(userId));
    }

    @GetMapping("/revenue")
    @PreAuthorize("hasRole('MASTER')")
    public ResponseEntity<List<RevenuePoint>> getRevenue(
            Authentication auth,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        Long userId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(dashboardService.getRevenueSeries(userId, from, to));
    }
}

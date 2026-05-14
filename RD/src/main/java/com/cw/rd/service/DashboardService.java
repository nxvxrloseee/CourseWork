package com.cw.rd.service;

import com.cw.rd.dto.dashboard.DashboardResponse;
import com.cw.rd.dto.dashboard.RevenuePoint;
import com.cw.rd.repository.TicketRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;
import java.util.*;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final TicketRepository ticketRepository;

    public DashboardResponse getDashboard(Long masterId) {
        LocalDateTime startOfMonth = LocalDateTime.now()
                .with(TemporalAdjusters.firstDayOfMonth())
                .withHour(0).withMinute(0).withSecond(0).withNano(0);

        DashboardResponse r = new DashboardResponse();
        r.setTotalNew(ticketRepository.countByStatusNameAndCreatedAtAfter("Новая", startOfMonth));
        r.setTotalInProgress(ticketRepository.countByMasterIdAndStatusNameAndCreatedAtAfter(
                masterId, "В работе", startOfMonth));
        r.setTotalCompleted(ticketRepository.countByMasterIdAndStatusNameAndCreatedAtAfter(
                masterId, "Завершена", startOfMonth));
        r.setTotalCancelled(ticketRepository.countByMasterIdAndStatusNameAndCreatedAtAfter(
                masterId, "Отменена", startOfMonth));
        return r;
    }

    public List<RevenuePoint> getRevenueSeries(Long masterId, LocalDate from, LocalDate to) {
        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.atTime(23, 59, 59);

        Map<LocalDate, RevenuePoint> byDay = new HashMap<>();
        for (Object[] row : ticketRepository.findRevenueSeries(masterId, fromDt, toDt)) {
            LocalDate day = ((Date) row[0]).toLocalDate();
            BigDecimal revenue = row[1] == null ? BigDecimal.ZERO : new BigDecimal(row[1].toString());
            long completed = ((Number) row[2]).longValue();
            byDay.put(day, new RevenuePoint(day, revenue, completed));
        }

        List<RevenuePoint> series = new ArrayList<>();
        for (LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) {
            series.add(byDay.getOrDefault(d, new RevenuePoint(d, BigDecimal.ZERO, 0)));
        }
        return series;
    }
}

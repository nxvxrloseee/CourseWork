package com.cw.rd.repository;

import com.cw.rd.entity.Ticket;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface TicketRepository extends JpaRepository<Ticket, Long>, JpaSpecificationExecutor<Ticket> {

    List<Ticket> findByCustomerIdOrderByCreatedAtDesc(Long customerId);

    List<Ticket> findByMasterIdOrderByCreatedAtDesc(Long masterId);

    long countByStatusNameAndCreatedAtAfter(String statusName, LocalDateTime after);

    long countByMasterIdAndStatusNameAndCreatedAtAfter(Long masterId, String statusName, LocalDateTime after);

    @Query(value = """
            SELECT CAST(sub.completion_date AS DATE) AS day,
                   COALESCE(SUM(sub.revenue), 0) AS revenue,
                   COUNT(*) AS completed
            FROM (
                SELECT t.id,
                       MAX(h.updated_at) AS completion_date,
                       (SELECT COALESCE(SUM(ts.price * ts.quantity), 0)
                        FROM ticket_services ts WHERE ts.id_ticket = t.id) AS revenue
                FROM tickets t
                JOIN ticket_status_history h ON h.id_ticket = t.id
                JOIN ticket_statuses s ON h.id_status = s.id
                WHERE s.name = 'Завершена'
                  AND (:masterId IS NULL OR t.id_master = :masterId)
                GROUP BY t.id
            ) sub
            WHERE sub.completion_date BETWEEN :from AND :to
            GROUP BY CAST(sub.completion_date AS DATE)
            ORDER BY day
            """, nativeQuery = true)
    List<Object[]> findRevenueSeries(@Param("masterId") Long masterId,
                                     @Param("from") LocalDateTime from,
                                     @Param("to") LocalDateTime to);
}

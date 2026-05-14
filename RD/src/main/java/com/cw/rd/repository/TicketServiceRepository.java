package com.cw.rd.repository;

import com.cw.rd.entity.TicketService;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TicketServiceRepository extends JpaRepository<TicketService, Long> {
    List<TicketService> findByTicketId(Long ticketId);
    boolean existsByTicketIdAndServiceId(Long ticketId, Long serviceId);
}

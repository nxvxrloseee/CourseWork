package com.cw.rd.repository;

import com.cw.rd.entity.TicketMedia;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TicketMediaRepository extends JpaRepository<TicketMedia, Long> {
    List<TicketMedia> findByTicketId(Long ticketId);
}

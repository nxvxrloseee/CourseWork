package com.cw.rd.repository;

import com.cw.rd.entity.TicketMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface TicketMessageRepository extends JpaRepository<TicketMessage, Long> {

    List<TicketMessage> findByTicketIdOrderByDateSentAsc(Long ticketId);

    @Modifying
    @Query("UPDATE TicketMessage m SET m.read = true WHERE m.ticket.id = :ticketId AND m.sender.id <> :userId AND m.read = false")
    void markAsRead(Long ticketId, Long userId);
}

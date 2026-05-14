package com.cw.rd.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "ticket_media")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TicketMedia {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_ticket", nullable = false)
    private Ticket ticket;

    @Column(name = "path_to_file", nullable = false, length = 255)
    private String pathToFile;
}

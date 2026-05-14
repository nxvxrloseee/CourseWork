package com.cw.rd.dto.chat;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class ChatMessageResponse {
    private Long id;
    private Long ticketId;
    private Long senderId;
    private String senderName;
    private String text;
    private LocalDateTime dateSent;
    private Boolean read;
}

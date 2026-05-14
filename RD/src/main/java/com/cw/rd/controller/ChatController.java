package com.cw.rd.controller;

import com.cw.rd.dto.chat.*;
import com.cw.rd.service.ChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;

    @MessageMapping("/chat.send")
    public void sendMessageWs(ChatMessageRequest request, Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        chatService.sendMessage(userId, request);
    }

    @PostMapping("/api/chat/send")
    public ResponseEntity<ChatMessageResponse> sendMessage(
            Authentication auth,
            @RequestBody ChatMessageRequest request) {
        Long userId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(chatService.sendMessage(userId, request));
    }

    @GetMapping("/api/chat/{ticketId}")
    public ResponseEntity<List<ChatMessageResponse>> getMessages(
            @PathVariable Long ticketId,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(chatService.getMessages(ticketId, userId));
    }
}

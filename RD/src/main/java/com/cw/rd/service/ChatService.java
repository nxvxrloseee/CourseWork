package com.cw.rd.service;

import com.cw.rd.dto.chat.*;
import com.cw.rd.entity.*;
import com.cw.rd.exception.ApiException;
import com.cw.rd.repository.TicketMessageRepository;
import com.cw.rd.repository.TicketRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChatService {

    private final TicketMessageRepository messageRepository;
    private final TicketRepository ticketRepository;
    private final UserService userService;
    private final NotificationService notificationService;
    private final SimpMessagingTemplate messagingTemplate;
    private final AesEncryptionService aesEncryptionService;

    @Transactional
    public ChatMessageResponse sendMessage(Long senderId, ChatMessageRequest request) {
        Ticket ticket = ticketRepository.findById(request.getTicketId())
                .orElseThrow(() -> ApiException.notFound("Заявка не найдена"));

        User sender = userService.getById(senderId);

        if (!ticket.getCustomer().getId().equals(senderId)
                && (ticket.getMaster() == null || !ticket.getMaster().getId().equals(senderId))) {
            throw ApiException.forbidden("Вы не участник этой заявки");
        }

        String encryptedText = aesEncryptionService.encryptText(request.getText());

        TicketMessage message = TicketMessage.builder()
                .ticket(ticket)
                .sender(sender)
                .text(encryptedText)
                .build();

        message = messageRepository.save(message);

        ChatMessageResponse response = toResponse(message);

        messagingTemplate.convertAndSend(
                "/topic/chat/" + ticket.getId(),
                response
        );

        Long recipientId = ticket.getCustomer().getId().equals(senderId)
                ? (ticket.getMaster() != null ? ticket.getMaster().getId() : null)
                : ticket.getCustomer().getId();

        if (recipientId != null) {
            notificationService.sendNotification(recipientId,
                    userService.getFullName(sender) + ": " + request.getText()
                            + " (заявка «" + ticket.getTitle() + "»)",
                    ticket.getId(), message.getId());
        }

        return response;
    }

    @Transactional
    public List<ChatMessageResponse> getMessages(Long ticketId, Long userId) {
        Ticket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> ApiException.notFound("Заявка не найдена"));

        if (!ticket.getCustomer().getId().equals(userId)
                && (ticket.getMaster() == null || !ticket.getMaster().getId().equals(userId))) {
            throw ApiException.forbidden("Вы не участник этой заявки");
        }

        messageRepository.markAsRead(ticketId, userId);

        return messageRepository.findByTicketIdOrderByDateSentAsc(ticketId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    private ChatMessageResponse toResponse(TicketMessage m) {
        ChatMessageResponse r = new ChatMessageResponse();
        r.setId(m.getId());
        r.setTicketId(m.getTicket().getId());
        r.setSenderId(m.getSender().getId());
        r.setSenderName(userService.getFullName(m.getSender()));
        r.setText(aesEncryptionService.decryptText(m.getText()));
        r.setDateSent(m.getDateSent());
        r.setRead(m.getRead());
        return r;
    }
}

package com.cw.rd.service;

import com.cw.rd.config.RabbitConfig;
import com.cw.rd.dto.notification.NotificationEvent;
import com.cw.rd.dto.notification.NotificationResponse;
import com.cw.rd.entity.Notification;
import com.cw.rd.entity.User;
import com.cw.rd.repository.NotificationRepository;
import com.cw.rd.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final RabbitTemplate rabbitTemplate;
    private final SimpMessagingTemplate messagingTemplate;

    public void sendNotification(Long userId, String text) {
        sendNotification(userId, text, null, null);
    }

    public void sendNotification(Long userId, String text, Long ticketId, Long messageId) {
        rabbitTemplate.convertAndSend(RabbitConfig.NOTIFICATION_QUEUE,
                NotificationEvent.builder()
                        .userId(userId)
                        .text(text)
                        .ticketId(ticketId)
                        .messageId(messageId)
                        .build());
    }

    @RabbitListener(queues = RabbitConfig.NOTIFICATION_QUEUE)
    @Transactional
    public void processNotification(NotificationEvent event) {
        if (event.getUserId() == null) return;
        User user = userRepository.findById(event.getUserId()).orElse(null);
        if (user == null) return;

        Notification notification = Notification.builder()
                .user(user)
                .text(event.getText())
                .ticketId(event.getTicketId())
                .messageId(event.getMessageId())
                .build();
        notificationRepository.save(notification);

        NotificationResponse response = toResponse(notification);
        messagingTemplate.convertAndSendToUser(
                user.getId().toString(),
                "/queue/notifications",
                response
        );
    }

    public List<NotificationResponse> getUserNotifications(Long userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    public long getUnreadCount(Long userId) {
        return notificationRepository.countByUserIdAndReadFalse(userId);
    }

    @Transactional
    public void markAsRead(Long notificationId, Long userId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Уведомление не найдено"));
        if (!notification.getUser().getId().equals(userId)) {
            throw new RuntimeException("Нет доступа");
        }
        notification.setRead(true);
        notificationRepository.save(notification);
    }

    @Transactional
    public void markAllAsRead(Long userId) {
        List<Notification> unread = notificationRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream().filter(n -> !n.getRead()).toList();
        unread.forEach(n -> n.setRead(true));
        notificationRepository.saveAll(unread);
    }

    private NotificationResponse toResponse(Notification n) {
        NotificationResponse r = new NotificationResponse();
        r.setId(n.getId());
        r.setText(n.getText());
        r.setRead(n.getRead());
        r.setTicketId(n.getTicketId());
        r.setMessageId(n.getMessageId());
        r.setCreatedAt(n.getCreatedAt());
        return r;
    }
}

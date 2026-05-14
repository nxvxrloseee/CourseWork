import { useEffect, useRef } from 'react';
import { Client } from '@stomp/stompjs';
import SockJS from 'sockjs-client';
import { useNavigate, useLocation } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { useAuthStore } from '../store/authStore';
import { useNotificationStore } from '../store/notificationStore';
import { markAsRead } from '../api/notifications';
import { toast } from 'sonner';

interface IncomingNotification {
  id: number;
  text: string;
  ticketId?: number;
  messageId?: number;
}

export function useWebSocket() {
  const token = useAuthStore((s) => s.token);
  const user = useAuthStore((s) => s.user);
  const increment = useNotificationStore((s) => s.increment);
  const navigate = useNavigate();
  const location = useLocation();
  const qc = useQueryClient();
  const clientRef = useRef<Client | null>(null);
  const locationRef = useRef(location);
  locationRef.current = location;

  useEffect(() => {
    if (!token || !user) return;

    const client = new Client({
      webSocketFactory: () => new SockJS('/ws'),
      connectHeaders: { Authorization: `Bearer ${token}` },
      onConnect: () => {
        client.subscribe(`/user/${user.id}/queue/notifications`, (msg) => {
          const notification: IncomingNotification = JSON.parse(msg.body);
          const loc = locationRef.current;
          const params = new URLSearchParams(loc.search);
          const onChatTab =
            notification.ticketId != null &&
            loc.pathname === `/tickets/${notification.ticketId}` &&
            params.get('tab') === 'chat';

          if (onChatTab) {
            qc.invalidateQueries({ queryKey: ['notifications'] });
            return;
          }

          increment();

          toast(notification.text, {
            duration: 6000,
            action: notification.ticketId
              ? {
                  label: notification.messageId ? 'К сообщению' : 'К заявке',
                  onClick: () => {
                    const path = notification.messageId
                      ? `/tickets/${notification.ticketId}?tab=chat&msg=${notification.messageId}`
                      : `/tickets/${notification.ticketId}`;
                    if (notification.id) markAsRead(notification.id).catch(() => {});
                    qc.invalidateQueries({ queryKey: ['notifications'] });
                    navigate(path);
                  },
                }
              : undefined,
          });
        });
      },
      reconnectDelay: 5000,
    });

    client.activate();
    clientRef.current = client;

    return () => {
      client.deactivate();
    };
  }, [token, user, increment, navigate, qc]);

  return clientRef;
}

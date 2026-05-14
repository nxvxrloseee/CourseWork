import { useQuery, useQueryClient } from '@tanstack/react-query';
import { getNotifications, markAsRead, markAllAsRead } from '../api/notifications';
import { useNotificationStore } from '../store/notificationStore';
import { useNavigate } from 'react-router-dom';
import dayjs from 'dayjs';
import { clsx } from 'clsx';
import type { Notification } from '../types';

export default function NotificationsPage() {
  const qc = useQueryClient();
  const navigate = useNavigate();
  const setUnreadCount = useNotificationStore((s) => s.setUnreadCount);

  const { data: notifications, isLoading } = useQuery<Notification[]>({
    queryKey: ['notifications'],
    queryFn: () => getNotifications().then((r) => r.data),
  });

  const handleClick = async (n: Notification) => {
    if (!n.read) {
      await markAsRead(n.id);
      qc.invalidateQueries({ queryKey: ['notifications'] });
      setUnreadCount(Math.max(0, useNotificationStore.getState().unreadCount - 1));
    }
    if (n.ticketId) {
      const path = n.messageId
        ? `/tickets/${n.ticketId}?tab=chat&msg=${n.messageId}`
        : `/tickets/${n.ticketId}`;
      navigate(path);
    }
  };

  const handleReadAll = async () => {
    await markAllAsRead();
    qc.invalidateQueries({ queryKey: ['notifications'] });
    setUnreadCount(0);
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-4">
        <h1 className="text-xl font-bold text-gray-800">Уведомления</h1>
        <button onClick={handleReadAll} className="text-sm text-blue-600 hover:underline">
          Прочитать все
        </button>
      </div>

      {isLoading ? <p className="text-gray-400">Загрузка...</p> : (
        <div className="flex flex-col gap-2">
          {notifications?.length === 0 && <p className="text-gray-400 text-sm">Нет уведомлений</p>}
          {notifications?.map((n) => (
            <div key={n.id} onClick={() => handleClick(n)}
              className={clsx('bg-white rounded-xl p-4 shadow-sm border transition cursor-pointer',
                n.read ? 'border-gray-100 opacity-60' : 'border-blue-200 hover:shadow-md')}>
              <p className="text-sm text-gray-800">{n.text}</p>
              <div className="flex justify-between items-center mt-1">
                <p className="text-xs text-gray-400">{dayjs(n.createdAt).format('DD.MM.YYYY HH:mm')}</p>
                {n.ticketId && (
                  <span className="text-[11px] text-blue-600">
                    {n.messageId ? '→ К сообщению' : '→ К заявке'}
                  </span>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

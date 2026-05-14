import { useParams, useNavigate, useSearchParams } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { getTicket, takeTicket, updateStatus, reschedule, getStatusHistory, addServiceToTicket, removeServiceFromTicket, updateTicketServiceQuantity } from '../api/tickets';
import { getMessages, sendMessage } from '../api/chat';
import { getActiveServices } from '../api/services';
import { useAuthStore } from '../store/authStore';
import { toast } from 'sonner';
import { useState, useRef, useEffect } from 'react';
import dayjs from 'dayjs';
import { clsx } from 'clsx';
import type { Ticket, ChatMessage, StatusHistory, ServiceItem } from '../types';
import { Client } from '@stomp/stompjs';
import SockJS from 'sockjs-client';
import { extractError } from '../api/client';

const allowedTransitions: Record<string, string[]> = {
  'В работе': ['Ожидает устройство', 'Отменена'],
  'Ожидает устройство': ['В ремонте', 'Отменена'],
  'В ремонте': ['Готово', 'Отменена'],
  'Готово': ['Завершена'],
};

const statusColor: Record<string, string> = {
  'Новая': 'bg-blue-100 text-blue-700',
  'В работе': 'bg-yellow-100 text-yellow-700',
  'Ожидает устройство': 'bg-purple-100 text-purple-700',
  'В ремонте': 'bg-orange-100 text-orange-700',
  'Готово': 'bg-teal-100 text-teal-700',
  'Завершена': 'bg-green-100 text-green-700',
  'Отменена': 'bg-red-100 text-red-700',
};

export default function TicketDetailPage() {
  const { id } = useParams<{ id: string }>();
  const ticketId = Number(id);
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const qc = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const token = useAuthStore((s) => s.token);
  const initialTab = (searchParams.get('tab') as 'info' | 'chat' | 'history') || 'info';
  const targetMessageId = searchParams.get('msg');
  const [tab, setTab] = useState<'info' | 'chat' | 'history'>(initialTab);
  const [msg, setMsg] = useState('');
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>([]);
  const [comment, setComment] = useState('');
  const [newDate, setNewDate] = useState('');
  const [selService, setSelService] = useState('');
  const [qty, setQty] = useState(1);
  const chatEndRef = useRef<HTMLDivElement>(null);
  const [lightbox, setLightbox] = useState<string | null>(null);

  const { data: ticket, isLoading } = useQuery<Ticket>({
    queryKey: ['ticket', ticketId],
    queryFn: () => getTicket(ticketId).then((r) => r.data),
  });

  const { data: history } = useQuery<StatusHistory[]>({
    queryKey: ['ticket-history', ticketId],
    queryFn: () => getStatusHistory(ticketId).then((r) => r.data),
    enabled: tab === 'history',
  });

  const { data: serviceList } = useQuery<ServiceItem[]>({
    queryKey: ['active-services'],
    queryFn: () => getActiveServices().then((r) => r.data),
    enabled: tab === 'info',
  });

  useEffect(() => {
    if (tab === 'chat') {
      getMessages(ticketId).then((r) => setChatMessages(r.data));
    }
  }, [tab, ticketId]);

  useEffect(() => {
    if (tab !== 'chat' || !token) return;
    const client = new Client({
      webSocketFactory: () => new SockJS('/ws'),
      connectHeaders: { Authorization: `Bearer ${token}` },
      onConnect: () => {
        client.subscribe(`/topic/chat/${ticketId}`, (m) => {
          setChatMessages((prev) => [...prev, JSON.parse(m.body)]);
        });
      },
    });
    client.activate();
    return () => { client.deactivate(); };
  }, [tab, ticketId, token]);

  useEffect(() => {
    if (tab !== 'chat' || chatMessages.length === 0) return;
    if (targetMessageId) {
      const el = document.getElementById(`msg-${targetMessageId}`);
      if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'center' });
        el.classList.add('ring-2', 'ring-yellow-400');
        setTimeout(() => el.classList.remove('ring-2', 'ring-yellow-400'), 2500);
        return;
      }
    }
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [chatMessages, tab, targetMessageId]);

  const handleSend = async () => {
    if (!msg.trim()) return;
    try {
      await sendMessage(ticketId, msg);
      setMsg('');
    } catch (e) { toast.error(extractError(e)); }
  };

  const handleTake = async () => {
    try {
      await takeTicket(ticketId);
      toast.success('Заявка принята в работу');
      qc.invalidateQueries({ queryKey: ['ticket', ticketId] });
    } catch (e) { toast.error(extractError(e)); }
  };

  const handleStatusChange = async (status: string) => {
    try {
      await updateStatus(ticketId, status, comment);
      toast.success('Статус обновлён');
      setComment('');
      qc.invalidateQueries({ queryKey: ['ticket', ticketId] });
    } catch (e) { toast.error(extractError(e)); }
  };

  const handleReschedule = async () => {
    if (!newDate) return;
    try {
      await reschedule(ticketId, newDate);
      toast.success('Время перенесено');
      setNewDate('');
      qc.invalidateQueries({ queryKey: ['ticket', ticketId] });
    } catch (e) { toast.error(extractError(e)); }
  };

  const handleAddService = async () => {
    if (!selService) return;
    try {
      await addServiceToTicket(ticketId, Number(selService), qty);
      toast.success('Услуга добавлена');
      setSelService(''); setQty(1);
      qc.invalidateQueries({ queryKey: ['ticket', ticketId] });
    } catch (e) { toast.error(extractError(e)); }
  };

  const handleRemoveService = async (tsId: number) => {
    try {
      await removeServiceFromTicket(ticketId, tsId);
      toast.success('Услуга удалена');
      qc.invalidateQueries({ queryKey: ['ticket', ticketId] });
    } catch (e) { toast.error(extractError(e)); }
  };

  const handleQtyChange = async (tsId: number, nextQty: number) => {
    if (nextQty < 1 || nextQty > 999) return;
    try {
      await updateTicketServiceQuantity(ticketId, tsId, nextQty);
      qc.invalidateQueries({ queryKey: ['ticket', ticketId] });
    } catch (e) { toast.error(extractError(e)); }
  };

  if (isLoading) return <p className="text-gray-400">Загрузка...</p>;
  if (!ticket) return <p className="text-red-500">Заявка не найдена</p>;

  const isMine = ticket.masterId === user?.id;
  const canEditServices = isMine && !['Готово', 'Завершена', 'Отменена'].includes(ticket.status);

  return (
    <div>
      <button onClick={() => navigate(-1)} className="text-sm text-blue-600 mb-3 hover:underline">&larr; Назад</button>

      {/* Two-column layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">

        {/* Left: ticket info + actions */}
        <div className="lg:col-span-1 flex flex-col gap-4">
          {/* Header card */}
          <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100">
            <div className="flex justify-between items-start mb-2">
              <h2 className="text-base font-bold text-gray-800 break-words min-w-0 flex-1 mr-2">#{ticket.id} {ticket.title}</h2>
              <span className={clsx('text-xs px-2 py-1 rounded-full font-medium whitespace-nowrap', statusColor[ticket.status] || 'bg-gray-100 text-gray-600')}>{ticket.status}</span>
            </div>
            <p className="text-sm text-gray-600 mb-3 break-words">{ticket.description}</p>
            <div className="flex flex-col gap-1.5 text-xs text-gray-500">
              <div className="flex justify-between"><span>Категория</span><span className="text-gray-700 font-medium">{ticket.category}</span></div>
              <div className="flex justify-between"><span>Заказчик</span><span className="text-gray-700">{ticket.customerName}</span></div>
              <div className="flex justify-between"><span>Мастер</span><span className="text-gray-700">{ticket.masterName || '—'}</span></div>
              <div className="flex justify-between"><span>Создана</span><span className="text-gray-700">{dayjs(ticket.createdAt).format('DD.MM.YYYY HH:mm')}</span></div>
              {ticket.selectedDatetime && <div className="flex justify-between"><span>Дата передачи</span><span className="text-gray-700">{dayjs(ticket.selectedDatetime).format('DD.MM.YYYY HH:mm')}</span></div>}
              {ticket.totalPrice > 0 && <div className="flex justify-between border-t pt-1.5 mt-1"><span className="font-medium text-gray-700">Итого</span><span className="font-bold text-gray-800">{ticket.totalPrice} ₽</span></div>}
              {ticket.totalPrice > 0 && (
                <div className={clsx('flex justify-between items-center mt-1 text-[11px] px-2 py-1 rounded',
                  ticket.pricesConfirmedAt ? 'bg-green-50 text-green-700' : 'bg-amber-50 text-amber-700')}>
                  <span>{ticket.pricesConfirmedAt ? '✓ Заказчик согласен с ценами' : '⏳ Согласие не получено'}</span>
                  {ticket.pricesConfirmedAt && (
                    <span className="font-medium">{dayjs(ticket.pricesConfirmedAt).format('DD.MM.YY HH:mm')}</span>
                  )}
                </div>
              )}
            </div>
          </div>

          {/* Photos */}
          {ticket.mediaUrls.length > 0 && (
            <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100">
              <h3 className="text-xs font-medium text-gray-500 mb-2">Фотографии</h3>
              <div className="flex gap-2 overflow-x-auto">
                {ticket.mediaUrls.map((url, i) => (
                  <img key={i} src={url} alt="" className="w-20 h-20 object-cover rounded-lg border cursor-pointer hover:opacity-80 transition flex-shrink-0"
                    onClick={() => setLightbox(url)} />
                ))}
              </div>
            </div>
          )}

          {/* Take button */}
          {ticket.status === 'Новая' && !ticket.masterId && (
            <button onClick={handleTake} className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700 transition w-full">
              Взять в работу
            </button>
          )}

          {/* Status actions */}
          {isMine && (allowedTransitions[ticket.status]?.length ?? 0) > 0 && (
            <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 flex flex-col gap-2.5">
              <h3 className="text-xs font-medium text-gray-500">Управление</h3>
              <div className="flex flex-wrap gap-2">
                {(allowedTransitions[ticket.status] ?? []).map((s) => (
                  <button key={s} onClick={() => handleStatusChange(s)}
                    className={clsx('px-3 py-1.5 rounded-lg text-xs font-medium transition',
                      s === 'Отменена' ? 'bg-red-500 text-white hover:bg-red-600'
                      : s === 'Завершена' ? 'bg-green-600 text-white hover:bg-green-700'
                      : 'bg-yellow-500 text-white hover:bg-yellow-600')}>
                    {s}
                  </button>
                ))}
              </div>
              <div>
                <input value={comment} onChange={(e) => setComment(e.target.value)} placeholder="Комментарий" maxLength={500}
                  className="w-full border rounded-lg px-3 py-1.5 text-sm" />
                {comment.length > 0 && <span className="text-[10px] text-gray-400 mt-0.5 block text-right">{comment.length}/500</span>}
              </div>
              <div className="flex gap-2 items-end">
                <div className="flex-1">
                  <label className="text-[10px] text-gray-500 block mb-0.5">Перенос даты</label>
                  <input type="datetime-local" value={newDate} onChange={(e) => setNewDate(e.target.value)}
                    className="w-full border rounded-lg px-2 py-1.5 text-sm" />
                </div>
                <button onClick={handleReschedule} className="bg-purple-500 text-white px-3 py-1.5 rounded-lg text-xs hover:bg-purple-600 transition">
                  Перенести
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Right: tabs content */}
        <div className="lg:col-span-2 flex flex-col gap-3">
          {/* Tabs */}
          <div className="flex gap-1">
            {(['info', 'chat', 'history'] as const).map((t) => (
              <button key={t} onClick={() => setTab(t)}
                className={clsx('px-4 py-2 rounded-lg text-sm transition',
                  tab === t ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200')}>
                {{ info: 'Услуги', chat: 'Чат', history: 'История' }[t]}
              </button>
            ))}
          </div>

          {/* Services list + inline add */}
          {tab === 'info' && (() => {
            const addedIds = new Set(ticket.services.map((s) => s.serviceId));
            const available = serviceList?.filter((s) => !addedIds.has(s.id)) ?? [];
            return (
              <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 flex flex-col gap-3">
                {ticket.services.length === 0 ? (
                  <p className="text-sm text-gray-400">Услуги не добавлены</p>
                ) : (
                  <table className="w-full text-sm">
                    <thead><tr className="text-left text-gray-500 border-b">
                      <th className="pb-2">Услуга</th><th className="pb-2">Цена</th><th className="pb-2">Кол-во</th><th className="pb-2">Сумма</th>{canEditServices && <th />}
                    </tr></thead>
                    <tbody>
                      {ticket.services.map((s) => (
                        <tr key={s.id} className="border-b last:border-0">
                          <td className="py-2">{s.serviceName}</td>
                          <td>{s.price} ₽</td>
                          <td>
                            {canEditServices ? (
                              <div className="inline-flex items-center gap-1">
                                <button onClick={() => handleQtyChange(s.id, s.quantity - 1)}
                                  disabled={s.quantity <= 1}
                                  className="w-6 h-6 rounded border border-gray-300 text-gray-600 hover:bg-gray-100 disabled:opacity-30 disabled:cursor-not-allowed transition flex items-center justify-center text-sm">−</button>
                                <span className="min-w-[24px] text-center font-medium">{s.quantity}</span>
                                <button onClick={() => handleQtyChange(s.id, s.quantity + 1)}
                                  disabled={s.quantity >= 999}
                                  className="w-6 h-6 rounded border border-gray-300 text-gray-600 hover:bg-gray-100 disabled:opacity-30 disabled:cursor-not-allowed transition flex items-center justify-center text-sm">+</button>
                              </div>
                            ) : (
                              s.quantity
                            )}
                          </td>
                          <td className="font-medium">{s.subtotal} ₽</td>
                          {canEditServices && <td><button onClick={() => handleRemoveService(s.id)} className="text-red-500 text-xs hover:underline">Удалить</button></td>}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}

                {canEditServices && (
                  <div className="border-t pt-3 mt-1">
                    <h4 className="text-xs font-medium text-gray-500 mb-2">Добавить услугу</h4>
                    <div className="flex flex-wrap gap-2 items-end">
                      <div className="flex-1 min-w-[180px]">
                        <select value={selService} onChange={(e) => setSelService(e.target.value)}
                          className="w-full border rounded-lg px-3 py-1.5 text-sm">
                          <option value="">{available.length === 0 ? 'Все услуги уже добавлены' : 'Выбрать услугу'}</option>
                          {available.map((s) => <option key={s.id} value={s.id}>{s.name} — {s.price} ₽</option>)}
                        </select>
                      </div>
                      <input type="number" min={1} value={qty} onChange={(e) => setQty(Number(e.target.value))}
                        className="w-20 border rounded-lg px-3 py-1.5 text-sm" placeholder="Кол-во" />
                      <button onClick={handleAddService} disabled={!selService}
                        className="bg-green-600 text-white px-4 py-1.5 rounded-lg text-sm hover:bg-green-700 transition disabled:bg-gray-300 disabled:cursor-not-allowed">
                        Добавить
                      </button>
                    </div>
                  </div>
                )}

                {!canEditServices && ticket.masterId && !isMine && (
                  <p className="text-xs text-gray-400 border-t pt-2">Услуги может изменять назначенный мастер</p>
                )}
              </div>
            );
          })()}

          {/* Chat */}
          {tab === 'chat' && (
            <div className="bg-white rounded-xl shadow-sm border border-gray-100 flex flex-col" style={{ height: 500 }}>
              <div className="flex-1 overflow-y-auto p-4 flex flex-col gap-3">
                {chatMessages.map((m) => (
                  <div key={m.id} id={`msg-${m.id}`} className={clsx('max-w-[75%] rounded-xl px-4 py-2.5 text-sm overflow-hidden shrink-0 transition-all',
                    m.senderId === user?.id ? 'bg-blue-600 text-white self-end' : 'bg-gray-100 text-gray-800 self-start')}>
                    <p className="text-xs opacity-70 mb-1 font-medium">{m.senderName}</p>
                    <p className="whitespace-pre-wrap break-words overflow-wrap-anywhere"
                      style={{ overflowWrap: 'anywhere', wordBreak: 'break-word' }}>{m.text}</p>
                    <p className="text-[10px] opacity-50 mt-1.5 flex items-center gap-1 justify-end flex-shrink-0">
                      {dayjs(m.dateSent).format('HH:mm')}
                      {m.senderId === user?.id && (
                        <span className={m.read ? 'text-sky-300' : ''}>
                          {m.read ? '✓✓' : '✓'}
                        </span>
                      )}
                    </p>
                  </div>
                ))}
                <div ref={chatEndRef} />
              </div>
              <div className="border-t p-3 flex flex-col gap-1">
                <div className="flex gap-2">
                  <input value={msg} onChange={(e) => setMsg(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && handleSend()}
                    placeholder="Сообщение..." maxLength={1000} className="flex-1 border rounded-lg px-3 py-2 text-sm" />
                  <button onClick={handleSend} className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700 transition">
                    Отправить
                  </button>
                </div>
                {msg.length > 0 && <span className="text-xs text-gray-400">{msg.length}/1000</span>}
              </div>
            </div>
          )}

          {/* History */}
          {tab === 'history' && (
            <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 flex flex-col gap-3">
              {history?.length === 0 && <p className="text-sm text-gray-400">Нет записей</p>}
              {history?.map((h, i) => (
                <div key={i} className="border-b last:border-0 pb-2">
                  <div className="flex justify-between text-sm">
                    <span className="font-medium">{h.status}</span>
                    <span className="text-gray-400 text-xs">{dayjs(h.updatedAt).format('DD.MM.YYYY HH:mm')}</span>
                  </div>
                  <p className="text-xs text-gray-500">{h.changedBy}</p>
                  {h.description && <p className="text-xs text-gray-400 mt-0.5">{h.description}</p>}
                </div>
              ))}
            </div>
          )}

        </div>
      </div>

      {/* Lightbox */}
      {lightbox && (
        <div className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center cursor-pointer"
          onClick={() => setLightbox(null)}>
          <button className="absolute top-4 right-4 text-white text-3xl font-bold hover:text-gray-300"
            onClick={() => setLightbox(null)}>&times;</button>
          <img src={lightbox} alt="" className="max-w-[90vw] max-h-[90vh] object-contain rounded-lg"
            onClick={(e) => e.stopPropagation()} />
        </div>
      )}
    </div>
  );
}

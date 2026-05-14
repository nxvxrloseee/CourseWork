import { useQuery } from '@tanstack/react-query';
import { getMasterHistory } from '../api/tickets';
import { useNavigate } from 'react-router-dom';
import { useState } from 'react';
import dayjs from 'dayjs';
import type { Ticket } from '../types';

export default function HistoryPage() {
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [sort, setSort] = useState('createdAtDesc');

  const { data: tickets, isLoading } = useQuery<Ticket[]>({
    queryKey: ['history', status, search, sort],
    queryFn: () => getMasterHistory({
      status: status || undefined,
      search: search.trim() || undefined,
      sort,
    }).then((r) => r.data),
  });

  return (
    <div>
      <h1 className="text-xl font-bold text-gray-800 mb-4">История заявок</h1>
      <div className="flex flex-wrap gap-3 mb-4">
        <input value={search} onChange={(e) => setSearch(e.target.value)}
          placeholder="Поиск: номер, заголовок, описание, заказчик, категория..."
          className="border border-gray-300 rounded-lg px-3 py-2 text-sm bg-white min-w-[280px] flex-1 max-w-md" />
        <select value={status} onChange={(e) => setStatus(e.target.value)}
          className="border border-gray-300 rounded-lg px-3 py-2 text-sm bg-white">
          <option value="">Все</option>
          <option value="Завершена">Завершена</option>
          <option value="Отменена">Отменена</option>
        </select>
        <select value={sort} onChange={(e) => setSort(e.target.value)}
          className="border border-gray-300 rounded-lg px-3 py-2 text-sm bg-white">
          <option value="createdAtDesc">Дата создания ↓</option>
          <option value="createdAtAsc">Дата создания ↑</option>
          <option value="idDesc">Номер ↓</option>
          <option value="idAsc">Номер ↑</option>
          <option value="scheduledDesc">Дата передачи ↓</option>
          <option value="scheduledAsc">Дата передачи ↑</option>
          <option value="statusAsc">Статус А-Я</option>
          <option value="statusDesc">Статус Я-А</option>
        </select>
      </div>
      {isLoading ? <p className="text-gray-400">Загрузка...</p> : (
        <div className="flex flex-col gap-3">
          {tickets?.length === 0 && <p className="text-gray-400 text-sm">Нет завершённых заявок</p>}
          {tickets?.map((t) => (
            <div key={t.id} onClick={() => navigate(`/tickets/${t.id}`)}
              className="bg-white rounded-xl p-4 shadow-sm cursor-pointer hover:shadow-md transition border border-gray-100">
              <div className="flex justify-between mb-1">
                <span className="font-medium text-sm text-gray-800">#{t.id} {t.title}</span>
                <span className={`text-xs px-2 py-0.5 rounded-full ${t.status === 'Завершена' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                  {t.status}
                </span>
              </div>
              <p className="text-xs text-gray-500 line-clamp-1 mb-1">{t.description}</p>
              <div className="flex justify-between text-xs text-gray-400">
                <span>{t.category} • {t.customerName}</span>
                <span className="flex items-center gap-2">
                  {t.totalPrice > 0 && <span className="text-emerald-600 font-medium">{t.totalPrice} ₽</span>}
                  <span>{dayjs(t.createdAt).format('DD.MM.YYYY')}</span>
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

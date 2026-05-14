import { useQuery } from '@tanstack/react-query';
import { getTickets } from '../api/tickets';
import { getCategories } from '../api/categories';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useState, useEffect } from 'react';
import type { Ticket, Category } from '../types';
import dayjs from 'dayjs';
import { clsx } from 'clsx';

const statusColors: Record<string, string> = {
  'Новая': 'bg-blue-100 text-blue-700',
  'В работе': 'bg-yellow-100 text-yellow-700',
  'Ожидает устройство': 'bg-purple-100 text-purple-700',
  'В ремонте': 'bg-orange-100 text-orange-700',
  'Готово': 'bg-emerald-100 text-emerald-700',
  'Завершена': 'bg-green-100 text-green-700',
  'Отменена': 'bg-red-100 text-red-700',
};

export default function TicketsPage() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [status, setStatus] = useState(searchParams.get('status') || '');
  const [categoryId, setCategoryId] = useState('');
  const [search, setSearch] = useState('');
  const [sort, setSort] = useState('createdAtDesc');

  useEffect(() => {
    const s = searchParams.get('status');
    if (s) setStatus(s);
  }, [searchParams]);

  const { data: tickets, isLoading } = useQuery<Ticket[]>({
    queryKey: ['tickets', status, categoryId, search, sort],
    queryFn: () => getTickets({
      status: status || undefined,
      categoryId: categoryId ? Number(categoryId) : undefined,
      search: search.trim() || undefined,
      sort,
      excludeCompleted: true,
    }).then((r) => r.data),
  });

  const { data: categories } = useQuery<Category[]>({
    queryKey: ['categories'],
    queryFn: () => getCategories().then((r) => r.data),
  });

  return (
    <div>
      <h1 className="text-xl font-bold text-gray-800 mb-4">Заявки</h1>
      <div className="flex flex-wrap gap-3 mb-4">
        <input value={search} onChange={(e) => setSearch(e.target.value)}
          placeholder="Поиск: номер, заголовок, описание, заказчик, мастер, категория..."
          className="border border-gray-300 rounded-lg px-3 py-2 text-sm bg-white min-w-[280px] flex-1 max-w-md" />
        <select value={status} onChange={(e) => setStatus(e.target.value)}
          className="border border-gray-300 rounded-lg px-3 py-2 text-sm bg-white">
          <option value="">Все статусы</option>
          {Object.keys(statusColors).filter((s) => s !== 'Завершена').map((s) => <option key={s} value={s}>{s}</option>)}
        </select>
        <select value={categoryId} onChange={(e) => setCategoryId(e.target.value)}
          className="border border-gray-300 rounded-lg px-3 py-2 text-sm bg-white">
          <option value="">Все категории</option>
          {categories?.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
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
          {tickets?.length === 0 && <p className="text-gray-400 text-sm">Заявок нет</p>}
          {tickets?.map((t) => (
            <div key={t.id} onClick={() => navigate(`/tickets/${t.id}`)}
              className="bg-white rounded-xl p-4 shadow-sm hover:shadow-md transition cursor-pointer border border-gray-100">
              <div className="flex items-center justify-between mb-2">
                <span className="font-medium text-gray-800 text-sm">#{t.id} {t.title}</span>
                <span className={clsx('text-xs px-2 py-0.5 rounded-full font-medium', statusColors[t.status])}>
                  {t.status}
                </span>
              </div>
              <p className="text-xs text-gray-500 line-clamp-1 mb-2">{t.description}</p>
              <div className="flex justify-between text-xs text-gray-400">
                <span>{t.category}</span>
                <span>{t.customerName}</span>
                <span>{dayjs(t.createdAt).format('DD.MM.YYYY HH:mm')}</span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

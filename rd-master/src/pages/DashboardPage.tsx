import { useQuery } from '@tanstack/react-query';
import { getDashboard, getRevenue } from '../api/dashboard';
import { ClipboardList, Clock, CheckCircle, XCircle } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useState } from 'react';
import dayjs from 'dayjs';
import RevenueChart from '../components/RevenueChart';
import type { DashboardData, RevenuePoint } from '../types';

const cards = [
  { key: 'totalNew' as const, label: 'Новые', icon: ClipboardList, color: 'bg-blue-50 text-blue-600', status: 'Новая' },
  { key: 'totalInProgress' as const, label: 'В работе', icon: Clock, color: 'bg-yellow-50 text-yellow-600', status: 'В работе' },
  { key: 'totalCompleted' as const, label: 'Завершены', icon: CheckCircle, color: 'bg-green-50 text-green-600', status: 'Завершена' },
  { key: 'totalCancelled' as const, label: 'Отменены', icon: XCircle, color: 'bg-red-50 text-red-600', status: 'Отменена' },
];

const presets: { label: string; days: number }[] = [
  { label: '7 дней', days: 7 },
  { label: '30 дней', days: 30 },
  { label: '90 дней', days: 90 },
];

export default function DashboardPage() {
  const navigate = useNavigate();

  const [from, setFrom] = useState(dayjs().subtract(29, 'day').format('YYYY-MM-DD'));
  const [to, setTo] = useState(dayjs().format('YYYY-MM-DD'));

  const { data, isLoading } = useQuery<DashboardData>({
    queryKey: ['dashboard'],
    queryFn: () => getDashboard().then((r) => r.data),
  });

  const { data: revenue, isLoading: revenueLoading } = useQuery<RevenuePoint[]>({
    queryKey: ['revenue', from, to],
    queryFn: () => getRevenue(from, to).then((r) => r.data),
  });

  const applyPreset = (days: number) => {
    setFrom(dayjs().subtract(days - 1, 'day').format('YYYY-MM-DD'));
    setTo(dayjs().format('YYYY-MM-DD'));
  };

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-xl font-bold text-gray-800 mb-4">Дашборд — текущий месяц</h1>
        {isLoading ? (
          <p className="text-gray-400">Загрузка...</p>
        ) : (
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            {cards.map((c) => (
              <button key={c.key} onClick={() => navigate(`/tickets?status=${c.status}`)}
                className={`${c.color} rounded-xl p-5 flex flex-col items-center gap-2 hover:shadow-md transition cursor-pointer`}>
                <c.icon size={28} />
                <span className="text-3xl font-bold">{data?.[c.key] ?? 0}</span>
                <span className="text-sm">{c.label}</span>
              </button>
            ))}
          </div>
        )}
      </div>

      <div className="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
        <div className="flex flex-wrap items-center justify-between gap-3 mb-4">
          <h2 className="text-base font-bold text-gray-800">Выручка за период</h2>
          <div className="flex flex-wrap items-center gap-2">
            {presets.map((p) => (
              <button key={p.days} onClick={() => applyPreset(p.days)}
                className="px-3 py-1.5 rounded-lg text-xs bg-gray-100 hover:bg-gray-200 text-gray-700 transition">
                {p.label}
              </button>
            ))}
            <input type="date" value={from} onChange={(e) => setFrom(e.target.value)}
              className="border rounded-lg px-2 py-1.5 text-xs" />
            <span className="text-xs text-gray-400">—</span>
            <input type="date" value={to} onChange={(e) => setTo(e.target.value)}
              className="border rounded-lg px-2 py-1.5 text-xs" />
          </div>
        </div>
        {revenueLoading ? (
          <p className="text-gray-400 text-sm">Загрузка графика...</p>
        ) : (
          <RevenueChart data={revenue ?? []} />
        )}
      </div>
    </div>
  );
}

import { useMemo, useState, useRef } from 'react';
import dayjs from 'dayjs';
import type { RevenuePoint } from '../types';

type Metric = 'revenue' | 'completed';

interface Props {
  data: RevenuePoint[];
}

function fmtMoney(v: number): string {
  if (v >= 1_000_000) return (v / 1_000_000).toFixed(1).replace(/\.0$/, '') + ' млн ₽';
  if (v >= 1_000) return (v / 1_000).toFixed(v >= 10_000 ? 0 : 1).replace(/\.0$/, '') + 'к ₽';
  return v.toLocaleString('ru-RU') + ' ₽';
}

function fmtAxis(v: number): string {
  if (v >= 1_000_000) return (v / 1_000_000).toFixed(1).replace(/\.0$/, '') + 'M';
  if (v >= 1_000) return (v / 1_000).toFixed(v >= 10_000 ? 0 : 1).replace(/\.0$/, '') + 'k';
  return String(v);
}

export default function RevenueChart({ data }: Props) {
  const [metric, setMetric] = useState<Metric>('revenue');
  const [hoverIdx, setHoverIdx] = useState<number | null>(null);
  const svgRef = useRef<SVGSVGElement>(null);

  const stats = useMemo(() => {
    const revVals = data.map((d) => Number(d.revenue || 0));
    const compVals = data.map((d) => d.completed);
    const totalRev = revVals.reduce((s, v) => s + v, 0);
    const totalComp = compVals.reduce((s, v) => s + v, 0);
    const activeDays = revVals.filter((v) => v > 0).length;
    const avgRev = activeDays ? totalRev / activeDays : 0;
    const avgComp = activeDays ? totalComp / activeDays : 0;
    let peakIdx = -1;
    let peakVal = -1;
    revVals.forEach((v, i) => { if (v > peakVal) { peakVal = v; peakIdx = i; } });
    return { totalRev, totalComp, avgRev, avgComp, activeDays, peakIdx, peakVal };
  }, [data]);

  if (data.length === 0) {
    return <p className="text-sm text-gray-400">Нет данных за выбранный период</p>;
  }

  const width = 800;
  const height = 300;
  const padding = { top: 24, right: 16, bottom: 40, left: 56 };
  const innerW = width - padding.left - padding.right;
  const innerH = height - padding.top - padding.bottom;

  const values = data.map((d) => metric === 'revenue' ? Number(d.revenue || 0) : d.completed);
  const max = Math.max(1, ...values);
  const avg = metric === 'revenue' ? stats.avgRev : stats.avgComp;
  const yTicks = 4;
  const slot = innerW / data.length;
  const barGap = data.length > 60 ? 1 : data.length > 30 ? 2 : 4;
  const barW = Math.max(2, slot - barGap);
  const labelEvery = Math.ceil(data.length / 8);

  const handleMove = (e: React.MouseEvent<SVGSVGElement>) => {
    const svg = svgRef.current;
    if (!svg) return;
    const rect = svg.getBoundingClientRect();
    const xRel = ((e.clientX - rect.left) / rect.width) * width;
    const xInner = xRel - padding.left;
    if (xInner < 0 || xInner > innerW) { setHoverIdx(null); return; }
    const idx = Math.min(data.length - 1, Math.max(0, Math.floor(xInner / slot)));
    setHoverIdx(idx);
  };

  const hover = hoverIdx != null ? data[hoverIdx] : null;
  const avgY = padding.top + innerH - (avg / max) * innerH;
  const tooltipX = hoverIdx != null ? padding.left + hoverIdx * slot + barW / 2 : 0;

  const activeColor = metric === 'revenue' ? '#10b981' : '#3b82f6';
  const peakColor = '#f59e0b';

  return (
    <div className="w-full">
      <div className="flex flex-wrap items-center justify-between gap-3 mb-3">
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 flex-1">
          <Stat label="Выручка" value={fmtMoney(stats.totalRev)} color="text-emerald-600" />
          <Stat label="Завершено" value={`${stats.totalComp} шт`} color="text-blue-600" />
          <Stat label="Средн./день*" value={metric === 'revenue' ? fmtMoney(stats.avgRev) : stats.avgComp.toFixed(1) + ' шт'} color="text-gray-700" />
          <Stat label="Пик"
            value={stats.peakIdx >= 0 ? `${fmtMoney(stats.peakVal)}` : '—'}
            sub={stats.peakIdx >= 0 ? dayjs(data[stats.peakIdx].date).format('DD.MM') : undefined}
            color="text-amber-600" />
        </div>
        <div className="flex bg-gray-100 rounded-lg p-1 text-xs">
          <button onClick={() => setMetric('revenue')}
            className={`px-3 py-1.5 rounded-md transition ${metric === 'revenue' ? 'bg-white shadow text-emerald-600 font-medium' : 'text-gray-500'}`}>
            Выручка
          </button>
          <button onClick={() => setMetric('completed')}
            className={`px-3 py-1.5 rounded-md transition ${metric === 'completed' ? 'bg-white shadow text-blue-600 font-medium' : 'text-gray-500'}`}>
            Заявок
          </button>
        </div>
      </div>

      <div className="relative overflow-x-auto">
        <svg ref={svgRef} viewBox={`0 0 ${width} ${height}`}
          className="min-w-[600px] w-full select-none"
          onMouseMove={handleMove}
          onMouseLeave={() => setHoverIdx(null)}>
          {Array.from({ length: yTicks + 1 }).map((_, i) => {
            const y = padding.top + (innerH * i) / yTicks;
            const value = max * (1 - i / yTicks);
            return (
              <g key={i}>
                <line x1={padding.left} y1={y} x2={padding.left + innerW} y2={y}
                  stroke="#e5e7eb" strokeDasharray="3 3" />
                <text x={padding.left - 8} y={y + 4} textAnchor="end" fontSize={10} fill="#9ca3af">
                  {metric === 'revenue' ? fmtAxis(Math.round(value)) : Math.round(value)}
                </text>
              </g>
            );
          })}

          {data.map((p, i) => {
            const v = values[i];
            const h = (v / max) * innerH;
            const x = padding.left + i * slot + barGap / 2;
            const y = padding.top + innerH - h;
            const isPeak = metric === 'revenue' && i === stats.peakIdx && v > 0;
            const isHover = hoverIdx === i;
            const fill = v === 0
              ? '#e5e7eb'
              : isPeak ? peakColor
              : isHover ? activeColor
              : activeColor;
            const opacity = hoverIdx != null && !isHover ? 0.55 : 1;
            return (
              <rect key={p.date} x={x} y={y} width={barW} height={h} rx={3}
                fill={fill} opacity={opacity} />
            );
          })}

          {avg > 0 && (
            <g>
              <line x1={padding.left} y1={avgY} x2={padding.left + innerW} y2={avgY}
                stroke="#9ca3af" strokeDasharray="6 4" strokeWidth={1.2} />
              <text x={padding.left + innerW - 4} y={avgY - 4} textAnchor="end"
                fontSize={10} fill="#6b7280">
                сред. {metric === 'revenue' ? fmtAxis(Math.round(avg)) : avg.toFixed(1)}
              </text>
            </g>
          )}

          {data.map((p, i) => {
            if (i % labelEvery !== 0) return null;
            const x = padding.left + i * slot + barW / 2 + barGap / 2;
            return (
              <text key={p.date} x={x} y={height - padding.bottom + 14}
                textAnchor="middle" fontSize={10} fill="#6b7280">
                {dayjs(p.date).format('DD.MM')}
              </text>
            );
          })}

          <line x1={padding.left} y1={padding.top} x2={padding.left} y2={padding.top + innerH}
            stroke="#9ca3af" />
          <line x1={padding.left} y1={padding.top + innerH} x2={padding.left + innerW} y2={padding.top + innerH}
            stroke="#9ca3af" />

          {hoverIdx != null && (
            <line x1={tooltipX} y1={padding.top} x2={tooltipX} y2={padding.top + innerH}
              stroke="#9ca3af" strokeDasharray="2 2" />
          )}
        </svg>

        {hover && (
          <div
            className="pointer-events-none absolute bg-gray-900 text-white text-xs rounded-lg px-3 py-2 shadow-lg whitespace-nowrap"
            style={{
              left: `${(tooltipX / width) * 100}%`,
              top: 4,
              transform: 'translateX(-50%)',
            }}>
            <div className="font-semibold">{dayjs(hover.date).format('DD.MM.YYYY (dd)')}</div>
            <div>Выручка: <span className="text-emerald-300">{fmtMoney(Number(hover.revenue || 0))}</span></div>
            <div>Заявок: <span className="text-blue-300">{hover.completed}</span></div>
            {hoverIdx === stats.peakIdx && stats.peakVal > 0 && (
              <div className="text-amber-300 mt-0.5">★ пиковый день</div>
            )}
          </div>
        )}
      </div>

      <p className="text-[10px] text-gray-400 mt-2">* среднее по активным дням ({stats.activeDays})</p>
    </div>
  );
}

function Stat({ label, value, sub, color }: { label: string; value: string; sub?: string; color: string }) {
  return (
    <div className="bg-gray-50 rounded-lg px-3 py-2">
      <div className="text-[10px] text-gray-500 uppercase tracking-wide">{label}</div>
      <div className={`text-sm font-bold ${color} leading-tight`}>{value}</div>
      {sub && <div className="text-[10px] text-gray-400">{sub}</div>}
    </div>
  );
}

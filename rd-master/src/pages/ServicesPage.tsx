import { useQuery, useQueryClient } from '@tanstack/react-query';
import { getAllServices, createService, updateService, deactivateService, activateService } from '../api/services';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { toast } from 'sonner';
import type { ServiceItem } from '../types';
import { clsx } from 'clsx';
import { extractError } from '../api/client';

interface Form { name: string; description: string; price: number }

export default function ServicesPage() {
  const qc = useQueryClient();
  const [editId, setEditId] = useState<number | null>(null);
  const [showForm, setShowForm] = useState(false);
  const { register, handleSubmit, reset, setValue, formState: { errors } } = useForm<Form>();

  const { data: services, isLoading } = useQuery<ServiceItem[]>({
    queryKey: ['services-all'],
    queryFn: () => getAllServices().then((r) => r.data),
  });

  const onSubmit = async (data: Form) => {
    try {
      if (editId) {
        await updateService(editId, data);
        toast.success('Услуга обновлена');
      } else {
        await createService(data);
        toast.success('Услуга создана');
      }
      reset(); setEditId(null); setShowForm(false);
      qc.invalidateQueries({ queryKey: ['services-all'] });
    } catch (e) { toast.error(extractError(e)); }
  };

  const startEdit = (s: ServiceItem) => {
    setEditId(s.id);
    setValue('name', s.name);
    setValue('description', s.description || '');
    setValue('price', s.price);
    setShowForm(true);
  };

  const toggle = async (s: ServiceItem) => {
    if (s.isActive) await deactivateService(s.id);
    else await activateService(s.id);
    qc.invalidateQueries({ queryKey: ['services-all'] });
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-4">
        <h1 className="text-xl font-bold text-gray-800">Прайс-лист</h1>
        <button onClick={() => { reset(); setEditId(null); setShowForm(!showForm); }}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700 transition">
          {showForm ? 'Скрыть' : '+ Добавить'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleSubmit(onSubmit)} className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 mb-4 flex flex-wrap gap-3 items-end">
          <div className="flex-1 min-w-[150px]">
            <label className="text-xs text-gray-500 block mb-1">Название</label>
            <input {...register('name', { required: 'Обязательное поле', maxLength: { value: 100, message: 'Максимум 100 символов' } })} maxLength={100} className="w-full border rounded-lg px-3 py-1.5 text-sm" />
            {errors.name && <span className="text-xs text-red-500 mt-0.5 block">{errors.name.message}</span>}
          </div>
          <div className="flex-1 min-w-[150px]">
            <label className="text-xs text-gray-500 block mb-1">Описание</label>
            <input {...register('description', { maxLength: { value: 500, message: 'Максимум 500 символов' } })} maxLength={500} className="w-full border rounded-lg px-3 py-1.5 text-sm" />
            {errors.description && <span className="text-xs text-red-500 mt-0.5 block">{errors.description.message}</span>}
          </div>
          <div>
            <label className="text-xs text-gray-500 block mb-1">Цена, ₽</label>
            <input type="number" step="0.01" {...register('price', { required: 'Обязательное поле', valueAsNumber: true, min: { value: 0.01, message: 'Цена должна быть больше 0' } })}
              className="w-28 border rounded-lg px-3 py-1.5 text-sm" />
            {errors.price && <span className="text-xs text-red-500 mt-0.5 block">{errors.price.message}</span>}
          </div>
          <button type="submit" className="bg-green-600 text-white px-4 py-1.5 rounded-lg text-sm hover:bg-green-700 transition">
            {editId ? 'Сохранить' : 'Создать'}
          </button>
        </form>
      )}

      {isLoading ? <p className="text-gray-400">Загрузка...</p> : (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
          <table className="w-full text-sm">
            <thead><tr className="text-left text-gray-500 bg-gray-50">
              <th className="px-4 py-3">Название</th><th className="px-4 py-3">Описание</th>
              <th className="px-4 py-3">Цена</th><th className="px-4 py-3">Статус</th><th className="px-4 py-3" />
            </tr></thead>
            <tbody>
              {services?.map((s) => (
                <tr key={s.id} className="border-t hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium">{s.name}</td>
                  <td className="px-4 py-3 text-gray-500 text-xs">{s.description || '—'}</td>
                  <td className="px-4 py-3">{s.price} ₽</td>
                  <td className="px-4 py-3">
                    <span className={clsx('text-xs px-2 py-0.5 rounded-full',
                      s.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500')}>
                      {s.isActive ? 'Активна' : 'Неактивна'}
                    </span>
                  </td>
                  <td className="px-4 py-3 flex gap-2">
                    <button onClick={() => startEdit(s)} className="text-blue-600 text-xs hover:underline">Изм.</button>
                    <button onClick={() => toggle(s)} className="text-xs hover:underline text-gray-500">
                      {s.isActive ? 'Деактив.' : 'Актив.'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

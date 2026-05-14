import { useForm } from 'react-hook-form';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import { login } from '../api/auth';
import { toast } from 'sonner';
import { useState } from 'react';

interface Form { email: string; password: string }

export default function LoginPage() {
  const { register, handleSubmit, formState: { errors } } = useForm<Form>();
  const navigate = useNavigate();
  const setAuth = useAuthStore((s) => s.setAuth);
  const [loading, setLoading] = useState(false);

  const onSubmit = async (data: Form) => {
    setLoading(true);
    try {
      const res = await login(data.email, data.password);
      if (res.data.role !== 'MASTER') {
        toast.error('Доступ только для мастеров');
        return;
      }
      setAuth(res.data.token, { id: res.data.userId, role: res.data.role } as any);
      navigate('/');
    } catch {
      toast.error('Неверный email или пароль');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="bg-white rounded-xl shadow-lg p-8 w-full max-w-sm">
        <h1 className="text-2xl font-bold text-center text-blue-600 mb-2">RepairDesk</h1>
        <p className="text-sm text-gray-500 text-center mb-6">Панель мастера</p>
        <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-4">
          <div>
            <label className="text-sm text-gray-600 mb-1 block">Email</label>
            <input {...register('email', { required: 'Обязательное поле', pattern: { value: /^[^@]+@[^@]+\.[^@]+$/, message: 'Введите корректный email' } })} type="email" maxLength={100}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" />
            {errors.email && <span className="text-xs text-red-500">{errors.email.message}</span>}
          </div>
          <div>
            <label className="text-sm text-gray-600 mb-1 block">Пароль</label>
            <input {...register('password', { required: 'Обязательное поле', minLength: { value: 6, message: 'Минимум 6 символов' } })} type="password" maxLength={100}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" />
            {errors.password && <span className="text-xs text-red-500">{errors.password.message}</span>}
          </div>
          <button type="submit" disabled={loading}
            className="bg-blue-600 text-white rounded-lg py-2 text-sm font-medium hover:bg-blue-700 disabled:opacity-50 transition">
            {loading ? 'Вход...' : 'Войти'}
          </button>
        </form>
      </div>
    </div>
  );
}

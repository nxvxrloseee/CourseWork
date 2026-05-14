import { useForm } from 'react-hook-form';
import { useAuthStore } from '../store/authStore';
import { updateProfile, changePassword } from '../api/user';
import { toast } from 'sonner';
import { useEffect } from 'react';
import { extractError } from '../api/client';

export default function ProfilePage() {
  const user = useAuthStore((s) => s.user);
  const setUser = useAuthStore((s) => s.setUser);

  const { register: rProfile, handleSubmit: hProfile, setValue, formState: { errors: ep } } = useForm<{ surname: string; name: string; patronymic: string }>();
  const { register: rPass, handleSubmit: hPass, reset: resetPass, formState: { errors: ePass }, watch: watchPass } = useForm<{ currentPassword: string; newPassword: string; confirmPassword: string }>();

  useEffect(() => {
    if (user) {
      setValue('surname', user.surname);
      setValue('name', user.name);
      setValue('patronymic', user.patronymic || '');
    }
  }, [user]);

  const onProfile = async (data: any) => {
    try {
      const res = await updateProfile(data);
      setUser(res.data);
      toast.success('Профиль обновлён');
    } catch (e) { toast.error(extractError(e)); }
  };

  const onPassword = async (data: any) => {
    try {
      await changePassword(data);
      toast.success('Пароль изменён');
      resetPass();
    } catch (e) {
      toast.error(extractError(e));
    }
  };

  return (
    <div className="max-w-lg">
      <h1 className="text-xl font-bold text-gray-800 mb-4">Профиль</h1>

      <form onSubmit={hProfile(onProfile)} className="bg-white rounded-xl p-5 shadow-sm border border-gray-100 mb-4 flex flex-col gap-3">
        <h2 className="text-sm font-medium text-gray-700">Личные данные</h2>
        <div>
          <input {...rProfile('surname', { required: 'Обязательное поле', minLength: { value: 2, message: 'Минимум 2 символа' }, maxLength: { value: 50, message: 'Максимум 50 символов' } })} placeholder="Фамилия" maxLength={50}
            className="w-full border rounded-lg px-3 py-2 text-sm" />
          {ep.surname && <span className="text-xs text-red-500 mt-0.5 block">{ep.surname.message}</span>}
        </div>
        <div>
          <input {...rProfile('name', { required: 'Обязательное поле', minLength: { value: 2, message: 'Минимум 2 символа' }, maxLength: { value: 50, message: 'Максимум 50 символов' } })} placeholder="Имя" maxLength={50}
            className="w-full border rounded-lg px-3 py-2 text-sm" />
          {ep.name && <span className="text-xs text-red-500 mt-0.5 block">{ep.name.message}</span>}
        </div>
        <div>
          <input {...rProfile('patronymic', { maxLength: { value: 50, message: 'Максимум 50 символов' } })} placeholder="Отчество" maxLength={50}
            className="w-full border rounded-lg px-3 py-2 text-sm" />
          {ep.patronymic && <span className="text-xs text-red-500 mt-0.5 block">{ep.patronymic.message}</span>}
        </div>
        <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700 transition">
          Сохранить
        </button>
      </form>

      <form onSubmit={hPass(onPassword)} className="bg-white rounded-xl p-5 shadow-sm border border-gray-100 flex flex-col gap-3">
        <h2 className="text-sm font-medium text-gray-700">Смена пароля</h2>
        <div>
          <input {...rPass('currentPassword', { required: 'Обязательное поле' })} type="password" placeholder="Текущий пароль" maxLength={100}
            className="w-full border rounded-lg px-3 py-2 text-sm" />
          {ePass.currentPassword && <span className="text-xs text-red-500 mt-0.5 block">{ePass.currentPassword.message}</span>}
        </div>
        <div>
          <input {...rPass('newPassword', { required: 'Обязательное поле', minLength: { value: 6, message: 'Минимум 6 символов' } })} type="password" placeholder="Новый пароль" maxLength={100}
            className="w-full border rounded-lg px-3 py-2 text-sm" />
          {ePass.newPassword && <span className="text-xs text-red-500 mt-0.5 block">{ePass.newPassword.message}</span>}
        </div>
        <div>
          <input {...rPass('confirmPassword', { required: 'Обязательное поле', validate: (v) => v === watchPass('newPassword') || 'Пароли не совпадают' })} type="password" placeholder="Подтвердите пароль" maxLength={100}
            className="w-full border rounded-lg px-3 py-2 text-sm" />
          {ePass.confirmPassword && <span className="text-xs text-red-500 mt-0.5 block">{ePass.confirmPassword.message}</span>}
        </div>
        <button type="submit" className="bg-green-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-green-700 transition">
          Сменить пароль
        </button>
      </form>
    </div>
  );
}

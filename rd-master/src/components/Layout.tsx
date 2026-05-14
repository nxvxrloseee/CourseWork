import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { LayoutDashboard, ClipboardList, History, Wrench, User, Bell, LogOut } from 'lucide-react';
import { useAuthStore } from '../store/authStore';
import { useNotificationStore } from '../store/notificationStore';
import { logout } from '../api/auth';
import { clsx } from 'clsx';

const nav = [
  { to: '/', icon: LayoutDashboard, label: 'Дашборд' },
  { to: '/tickets', icon: ClipboardList, label: 'Заявки' },
  { to: '/history', icon: History, label: 'История' },
  { to: '/services', icon: Wrench, label: 'Прайс-лист' },
  { to: '/profile', icon: User, label: 'Профиль' },
];

export default function Layout() {
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const clearAuth = useAuthStore((s) => s.clearAuth);
  const unread = useNotificationStore((s) => s.unreadCount);

  const handleLogout = async () => {
    try { await logout(); } catch { /* ignore */ }
    clearAuth();
    navigate('/login');
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col md:flex-row">
      {/* Sidebar desktop */}
      <aside className="hidden md:flex flex-col w-56 bg-white border-r border-gray-200 p-4 gap-1 fixed h-full">
        <h1 className="text-lg font-bold text-blue-600 mb-6 px-3">RepairDesk</h1>
        {nav.map((n) => (
          <Link key={n.to} to={n.to}
            className={clsx('flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition',
              pathname === n.to ? 'bg-blue-50 text-blue-600 font-medium' : 'text-gray-600 hover:bg-gray-100')}>
            <n.icon size={18} />{n.label}
          </Link>
        ))}
        <Link to="/notifications"
          className={clsx('flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition',
            pathname === '/notifications' ? 'bg-blue-50 text-blue-600 font-medium' : 'text-gray-600 hover:bg-gray-100')}>
          <Bell size={18} />Уведомления
          {unread > 0 && <span className="ml-auto bg-red-500 text-white text-xs px-1.5 py-0.5 rounded-full">{unread}</span>}
        </Link>
        <button onClick={handleLogout}
          className="flex items-center gap-3 px-3 py-2 rounded-lg text-sm text-gray-600 hover:bg-gray-100 mt-auto transition">
          <LogOut size={18} />Выйти
        </button>
      </aside>

      {/* Main content */}
      <main className="flex-1 md:ml-56 p-4 md:p-6">
        <Outlet />
      </main>

      {/* Bottom nav mobile */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 flex justify-around py-2 z-50">
        {nav.slice(0, 4).map((n) => (
          <Link key={n.to} to={n.to}
            className={clsx('flex flex-col items-center text-xs gap-0.5',
              pathname === n.to ? 'text-blue-600' : 'text-gray-400')}>
            <n.icon size={20} />{n.label}
          </Link>
        ))}
        <Link to="/notifications"
          className={clsx('flex flex-col items-center text-xs gap-0.5 relative',
            pathname === '/notifications' ? 'text-blue-600' : 'text-gray-400')}>
          <Bell size={20} />
          {unread > 0 && <span className="absolute -top-1 right-0 bg-red-500 text-white text-[10px] w-4 h-4 rounded-full flex items-center justify-center">{unread}</span>}
          Ещё
        </Link>
      </nav>
    </div>
  );
}

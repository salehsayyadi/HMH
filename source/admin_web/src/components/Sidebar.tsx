import React from 'react';
import { 
  LayoutDashboard, 
  Users, 
  School, 
  CalendarCheck, 
  Clock, 
  CalendarOff, 
  ShieldAlert, 
  BarChart3, 
  History, 
  Settings, 
  LogOut,
  Server
} from 'lucide-react';
import { User } from '../services/api';

export type SectionType = 
  | 'dashboard' 
  | 'users' 
  | 'schools' 
  | 'reservations' 
  | 'slots' 
  | 'holidays' 
  | 'restrictions' 
  | 'reports' 
  | 'audit' 
  | 'settings';

interface SidebarProps {
  currentSection: SectionType;
  onSelectSection: (section: SectionType) => void;
  currentUser: User | null;
  onLogout: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentSection,
  onSelectSection,
  currentUser,
  onLogout
}) => {
  const menuItems: { id: SectionType; label: string; icon: React.ReactNode }[] = [
    { id: 'dashboard', label: 'داشبورد', icon: <LayoutDashboard size={19} /> },
    { id: 'users', label: 'مدیریت کاربران', icon: <Users size={19} /> },
    { id: 'schools', label: 'مدیریت مدارس', icon: <School size={19} /> },
    { id: 'reservations', label: 'مدیریت رزروها', icon: <CalendarCheck size={19} /> },
    { id: 'slots', label: 'مدیریت ساعت‌ها', icon: <Clock size={19} /> },
    { id: 'holidays', label: 'مدیریت تعطیلات', icon: <CalendarOff size={19} /> },
    { id: 'restrictions', label: 'مدیریت محدودیت‌ها', icon: <ShieldAlert size={19} /> },
    { id: 'reports', label: 'گزارش‌ها', icon: <BarChart3 size={19} /> },
    { id: 'audit', label: 'تاریخچه فعالیت‌ها', icon: <History size={19} /> },
    { id: 'settings', label: 'تنظیمات سامانه', icon: <Settings size={19} /> },
  ];

  return (
    <aside className="w-64 bg-white border-l border-brand-border flex flex-col justify-between shadow-card h-screen sticky top-0 select-none">
      <div>
        {/* Organization Brand */}
        <div className="p-5 border-b border-brand-border flex items-center gap-3">
          <div className="w-12 h-12 rounded-xl bg-brand-light border border-brand-border flex items-center justify-center p-1.5 shadow-sm">
            <img src="/logo.svg" alt="HMH Logo" className="w-full h-full object-contain" />
          </div>
          <div>
            <h1 className="text-sm font-bold text-brand-dark leading-tight">
              مدارس امام حسین (ع)
            </h1>
            <p className="text-xs text-brand-muted mt-0.5">
              پنل مدیریت کل سیستم
            </p>
          </div>
        </div>

        {/* Super Admin User Profile Widget */}
        <div className="p-4 mx-3 my-3 bg-brand-light rounded-card border border-brand-border flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-brand-primary text-white flex items-center justify-center font-bold text-base shadow-sm">
            {currentUser?.first_name?.[0] || 'م'}
          </div>
          <div className="overflow-hidden">
            <div className="text-sm font-semibold text-brand-text truncate">
              {currentUser?.full_name || 'مدیر کل سامانه'}
            </div>
            <div className="text-xs text-brand-secondary font-medium flex items-center gap-1.5 mt-0.5">
              <span className="w-2 h-2 rounded-full bg-brand-secondary animate-pulse"></span>
              مدیر ارشد سیستم
            </div>
          </div>
        </div>

        {/* Navigation Menu */}
        <nav className="px-3 space-y-1">
          {menuItems.map((item) => {
            const isActive = currentSection === item.id;
            return (
              <button
                key={item.id}
                onClick={() => onSelectSection(item.id)}
                className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-btn text-sm font-medium transition-all duration-200 text-right ${
                  isActive
                    ? 'bg-brand-primary text-white shadow-soft font-semibold translate-x-[-2px]'
                    : 'text-brand-text hover:bg-brand-light hover:text-brand-emerald'
                }`}
              >
                <span className={`${isActive ? 'text-white' : 'text-brand-muted'}`}>
                  {item.icon}
                </span>
                <span>{item.label}</span>
              </button>
            );
          })}
        </nav>
      </div>

      {/* Logout Action */}
      <div className="p-4 border-t border-brand-border">
        <button
          onClick={onLogout}
          className="w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-btn text-sm font-medium text-res-redText bg-res-red hover:bg-red-100 transition-colors duration-200"
        >
          <LogOut size={17} />
          <span>خروج از حساب مدیریت</span>
        </button>
      </div>
    </aside>
  );
};

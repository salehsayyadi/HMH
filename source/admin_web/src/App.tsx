import React, { useState, useEffect } from 'react';
import { Sidebar, SectionType } from './components/Sidebar';
import { LoginModal } from './components/LoginModal';
import { DashboardSection } from './sections/DashboardSection';
import { UserManagementSection } from './sections/UserManagementSection';
import { SchoolManagementSection } from './sections/SchoolManagementSection';
import { ReservationManagementSection } from './sections/ReservationManagementSection';
import { TimeSlotManagementSection } from './sections/TimeSlotManagementSection';
import { HolidayManagementSection } from './sections/HolidayManagementSection';
import { RestrictionManagementSection } from './sections/RestrictionManagementSection';
import { ReportsSection } from './sections/ReportsSection';
import { AuditLogsSection } from './sections/AuditLogsSection';
import { ServerSettingsSection } from './sections/ServerSettingsSection';
import { apiRequest, clearTokens, getAccessToken, User } from './services/api';
import { Calendar, Bell, Shield, Wifi } from 'lucide-react';

export const App: React.FC = () => {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [currentSection, setCurrentSection] = useState<SectionType>('dashboard');
  const [loadingAuth, setLoadingAuth] = useState(true);
  const [wsConnected, setWsConnected] = useState(false);
  const [notification, setNotification] = useState<string | null>(null);

  // Check existing session
  useEffect(() => {
    const checkAuth = async () => {
      const token = getAccessToken();
      if (!token) {
        setLoadingAuth(false);
        return;
      }
      try {
        const user = await apiRequest<User>('/auth/me');
        if (user.role === 'super_admin') {
          setCurrentUser(user);
        } else {
          clearTokens();
        }
      } catch {
        clearTokens();
      } finally {
        setLoadingAuth(false);
      }
    };

    checkAuth();

    const handleUnauthorized = () => {
      setCurrentUser(null);
    };
    window.addEventListener('auth:unauthorized', handleUnauthorized);
    return () => window.removeEventListener('auth:unauthorized', handleUnauthorized);
  }, []);

  // WebSocket real-time connection per Part 35
  useEffect(() => {
    if (!currentUser) return;

    let socket: WebSocket | null = null;
    let reconnectTimeout: any = null;

    const connectWs = () => {
      const token = getAccessToken();
      const wsUrl = `ws://localhost:8000/ws?token=${token || ''}`;
      try {
        socket = new WebSocket(wsUrl);

        socket.onopen = () => {
          setWsConnected(true);
        };

        socket.onmessage = (event) => {
          try {
            const data = JSON.parse(event.data);
            if (data.event === 'reservation.created') {
              setNotification(`رزرو جدید توسط مدرسه ${data.data?.school_name} ثبت شد.`);
              setTimeout(() => setNotification(null), 5000);
            } else if (data.event === 'reservation.cancelled') {
              setNotification(`رزرو تاریخ ${data.data?.date} لغو و زمان آن آزاد شد.`);
              setTimeout(() => setNotification(null), 5000);
            }
          } catch {
            // non-json or ping-pong
          }
        };

        socket.onclose = () => {
          setWsConnected(false);
          reconnectTimeout = setTimeout(connectWs, 3000);
        };

        socket.onerror = () => {
          setWsConnected(false);
        };
      } catch {
        setWsConnected(false);
      }
    };

    connectWs();

    return () => {
      if (socket) socket.close();
      if (reconnectTimeout) clearTimeout(reconnectTimeout);
    };
  }, [currentUser]);

  const handleLogout = () => {
    clearTokens();
    setCurrentUser(null);
  };

  if (loadingAuth) {
    return (
      <div className="h-screen flex items-center justify-center bg-brand-bg">
        <div className="text-center space-y-3">
          <div className="w-12 h-12 border-4 border-brand-primary border-t-transparent rounded-full animate-spin mx-auto"></div>
          <p className="text-xs text-brand-muted font-medium">در حال بررسی نشست امنیتی مدیر...</p>
        </div>
      </div>
    );
  }

  if (!currentUser) {
    return <LoginModal onSuccess={(user) => setCurrentUser(user)} />;
  }

  return (
    <div className="flex h-screen overflow-hidden bg-brand-bg font-sans text-brand-text">
      {/* Sidebar */}
      <Sidebar
        currentSection={currentSection}
        onSelectSection={setCurrentSection}
        currentUser={currentUser}
        onLogout={handleLogout}
      />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col overflow-y-auto">
        {/* Top Navbar */}
        <header className="bg-white border-b border-brand-border px-8 py-3.5 flex items-center justify-between sticky top-0 z-30 shadow-sm">
          <div className="flex items-center gap-3">
            <span className="text-xs font-bold text-brand-dark">
              سامانه مدیریت مرکزی آمفی‌تئاتر مدارس امام حسین (ع)
            </span>
            <span className="text-brand-border font-light">|</span>
            <span className="text-xs text-brand-muted flex items-center gap-1.5 font-medium">
              <Calendar size={14} className="text-brand-secondary" />
              امروز: دوشنبه، ۱۱ آبان ۱۴۰۵
            </span>
          </div>

          <div className="flex items-center gap-4">
            {/* Live WS Status */}
            <div className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-bold ${
              wsConnected ? 'bg-emerald-50 text-brand-emerald border border-emerald-200' : 'bg-gray-100 text-gray-500'
            }`}>
              <Wifi size={12} className={wsConnected ? 'animate-pulse' : ''} />
              <span>{wsConnected ? 'همگام‌سازی بلادرنگ فعال' : 'اتصال آفلاین'}</span>
            </div>

            {/* Notification alert if any */}
            {notification && (
              <div className="px-3 py-1 bg-blue-50 border border-blue-200 text-res-blueText text-xs font-medium rounded-full animate-fade-in flex items-center gap-1.5">
                <Bell size={12} />
                <span>{notification}</span>
              </div>
            )}
          </div>
        </header>

        {/* Content Body */}
        <main className="p-8 space-y-6 flex-1">
          {currentSection === 'dashboard' && <DashboardSection />}
          {currentSection === 'users' && <UserManagementSection />}
          {currentSection === 'schools' && <SchoolManagementSection />}
          {currentSection === 'reservations' && <ReservationManagementSection />}
          {currentSection === 'slots' && <TimeSlotManagementSection />}
          {currentSection === 'holidays' && <HolidayManagementSection />}
          {currentSection === 'restrictions' && <RestrictionManagementSection />}
          {currentSection === 'reports' && <ReportsSection />}
          {currentSection === 'audit' && <AuditLogsSection />}
          {currentSection === 'settings' && <ServerSettingsSection />}
        </main>
      </div>
    </div>
  );
};

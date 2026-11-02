import React, { useEffect, useState } from 'react';
import { 
  Users, 
  School, 
  Calendar, 
  Clock, 
  CheckCircle2, 
  XCircle, 
  AlertTriangle, 
  TrendingUp,
  RefreshCw
} from 'lucide-react';
import { 
  ResponsiveContainer, 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  Tooltip, 
  CartesianGrid, 
  PieChart, 
  Pie, 
  Cell 
} from 'recharts';
import { apiRequest, DashboardStats } from '../services/api';

const COLORS = ['#006B52', '#10A77D', '#1554A3', '#B42335', '#F59E0B'];

const offlineFallbackStats: DashboardStats = {
  total_users: 7,
  total_schools: 6,
  today_reservations: 2,
  upcoming_reservations: 14,
  available_slots_week: 19,
  reserved_slots_week: 12,
  blocked_slots_week: 4,
  monthly_reservations: 48,
  monthly_cancellations: 3,
  monthly_trend: [
    { month: 'خرداد', count: 32 },
    { month: 'تیر', count: 18 },
    { month: 'مرداد', count: 24 },
    { month: 'شهریور', count: 39 },
    { month: 'مهر', count: 54 },
    { month: 'آبان', count: 48 },
  ],
  status_distribution: [
    { status: 'تأیید شده', count: 48 },
    { status: 'در انتظار', count: 5 },
    { status: 'لغو شده', count: 3 },
  ],
  reservations_by_school: [
    { school: 'دبیرستان پسرانه دوره دوم امام حسین (ع)', count: 15 },
    { school: 'دبستان پسرانه امام حسین (ع)', count: 14 },
    { school: 'دبیرستان دخترانه دوره اول امام حسین (ع)', count: 12 },
    { school: 'دبستان دخترانه امام حسین (ع)', count: 11 },
    { school: 'دبیرستان دخترانه دوره دوم امام حسین (ع)', count: 8 },
    { school: 'دبیرستان پسرانه دوره اول امام حسین (ع)', count: 7 },
  ],
  recent_activity: [
    { id: 101, school: 'دبیرستان پسرانه دوره دوم', user: 'محمدمحسن کارستان', date: '۱۱ آبان ۱۴۰۵', time: '۱۵:۰۰ تا ۱۷:۰۰', status: 'تأیید شده', created_at: new Date().toISOString() },
    { id: 102, school: 'دبستان دخترانه', user: 'فاطمه کریمی', date: '۱۲ آبان ۱۴۰۵', time: '۰۸:۰۰ تا ۱۰:۰۰', status: 'تأیید شده', created_at: new Date().toISOString() },
    { id: 103, school: 'دبیرستان دخترانه دوره اول', user: 'مریم حسینی', date: '۱۴ آبان ۱۴۰۵', time: '۱۲:۳۰ تا ۱۴:۳۰', status: 'تأیید شده', created_at: new Date().toISOString() },
    { id: 104, school: 'دبستان پسرانه', user: 'علی رضایی', date: '۱۵ آبان ۱۴۰۵', time: '۱۰:۰۰ تا ۱۲:۰۰', status: 'تأیید شده', created_at: new Date().toISOString() },
  ]
};

export const DashboardSection: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [isOfflinePreview, setIsOfflinePreview] = useState(false);

  const fetchStats = async () => {
    try {
      setLoading(true);
      const data = await apiRequest<DashboardStats>('/reports/dashboard');
      setStats(data);
      setIsOfflinePreview(false);
    } catch {
      // Fallback to high-fidelity offline preview stats
      setStats(offlineFallbackStats);
      setIsOfflinePreview(true);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStats();
  }, []);

  if (loading && !stats) {
    return (
      <div className="flex flex-col items-center justify-center h-96 gap-3">
        <RefreshCw className="animate-spin text-brand-primary" size={32} />
        <p className="text-xs text-brand-muted font-medium">در حال دریافت جدیدترین آمار و اطلاعات پایگاه داده...</p>
      </div>
    );
  }

  if (!stats) return null;

  const kpis = [
    { label: 'کل مدارس تحت پوشش', value: stats.total_schools, icon: <School size={22} />, color: 'bg-emerald-50 text-brand-primary border-emerald-100' },
    { label: 'کل کاربران سازمانی', value: stats.total_users, icon: <Users size={22} />, color: 'bg-blue-50 text-brand-primary border-blue-100' },
    { label: 'رزروهای امروز', value: stats.today_reservations, icon: <Calendar size={22} />, color: 'bg-teal-50 text-brand-emerald border-teal-100' },
    { label: 'رزروهای پیش‌رو', value: stats.upcoming_reservations, icon: <Clock size={22} />, color: 'bg-green-50 text-brand-secondary border-green-100' },
    { label: 'رزروهای این ماه', value: stats.monthly_reservations, icon: <CheckCircle2 size={22} />, color: 'bg-brand-pastel text-brand-dark border-brand-border' },
    { label: 'لغوشده‌های این ماه', value: stats.monthly_cancellations, icon: <XCircle size={22} />, color: 'bg-res-red text-res-redText border-red-100' },
  ];

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Top Welcome & Actions */}
      <div className="flex items-center justify-between bg-white p-5 rounded-card border border-brand-border shadow-soft">
        <div>
          <h2 className="text-lg font-bold text-brand-dark">نمای کلی داشبورد مدیریتی</h2>
          <p className="text-xs text-brand-muted mt-1">
            آمار تحلیلی و وضعیت لحظه‌ای سالن آمفی‌تئاتر مرکزی مدارس امام حسین (ع)
          </p>
        </div>
        <button
          onClick={fetchStats}
          className="flex items-center gap-2 px-3.5 py-2 text-xs font-semibold text-brand-primary bg-brand-light hover:bg-brand-pastel rounded-btn transition-colors duration-150 border border-brand-border"
        >
          <RefreshCw size={14} />
          <span>به‌روزرسانی داده‌ها</span>
        </button>
      </div>

      {isOfflinePreview && (
        <div className="p-3.5 bg-amber-50 border border-amber-200 text-amber-900 rounded-card flex items-center gap-3 text-xs">
          <AlertTriangle size={18} className="text-amber-700 shrink-0" />
          <span>
            <strong>حالت پیش‌نمایش آفلاین:</strong> ارتباط با پایگاه‌داده MySQL سرور مرکزی هنوز فعال نیست. آمارها به صورت پیش‌فرض نمایش داده شده‌اند. برای اتصال سرور، به بخش «تنظیمات سامانه» مراجعه نمایید.
          </span>
        </div>
      )}

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
        {kpis.map((kpi, idx) => (
          <div 
            key={idx}
            className={`p-4 rounded-card border ${kpi.color} shadow-soft flex flex-col justify-between transition-transform hover:-translate-y-0.5 duration-200`}
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-medium text-brand-muted">{kpi.label}</span>
              <div className="p-2 rounded-xl bg-white shadow-sm">{kpi.icon}</div>
            </div>
            <div className="text-2xl font-black text-brand-text mt-3">
              {kpi.value.toLocaleString('fa-IR')}
            </div>
          </div>
        ))}
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Trend Chart */}
        <div className="lg:col-span-2 bg-white p-5 rounded-card border border-brand-border shadow-soft">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm font-bold text-brand-dark flex items-center gap-2">
              <TrendingUp size={16} className="text-brand-primary" />
              روند ماهانه رزروهای سالن
            </h3>
            <span className="text-xs text-brand-muted">سال تحصیلی ۱۴۰۳</span>
          </div>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={stats.monthly_trend} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E8ECEE" />
                <XAxis dataKey="month" tick={{ fontSize: 11, fill: '#71867E' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 11, fill: '#71867E' }} axisLine={false} tickLine={false} />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#004D3B', color: '#fff', borderRadius: '10px', fontSize: '12px', border: 'none' }} 
                  formatter={(val: any) => [`${val} رزرو`, 'تعداد']}
                />
                <Bar dataKey="count" fill="#006B52" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Status Distribution Pie */}
        <div className="bg-white p-5 rounded-card border border-brand-border shadow-soft flex flex-col justify-between">
          <div>
            <h3 className="text-sm font-bold text-brand-dark mb-4">توزیع وضعیت رزروها</h3>
            <div className="h-52">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={stats.status_distribution}
                    cx="50%"
                    cy="50%"
                    innerRadius={50}
                    outerRadius={80}
                    paddingAngle={4}
                    dataKey="count"
                    nameKey="status"
                  >
                    {stats.status_distribution.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip 
                    contentStyle={{ backgroundColor: '#004D3B', color: '#fff', borderRadius: '10px', fontSize: '12px', border: 'none' }}
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </div>
          <div className="flex justify-center gap-4 text-xs text-brand-muted pt-2 border-t border-brand-border">
            {stats.status_distribution.map((s, idx) => (
              <div key={idx} className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: COLORS[idx % COLORS.length] }}></span>
                <span>{s.status}: {s.count.toLocaleString('fa-IR')}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* School Breakdown & Recent Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Reservations by School */}
        <div className="bg-white p-5 rounded-card border border-brand-border shadow-soft">
          <h3 className="text-sm font-bold text-brand-dark mb-4">میزان استفاده مدارس از آمفی‌تئاتر</h3>
          <div className="space-y-3">
            {stats.reservations_by_school.map((sc, idx) => {
              const maxCount = Math.max(...stats.reservations_by_school.map(s => s.count), 1);
              const pct = Math.round((sc.count / maxCount) * 100);
              return (
                <div key={idx} className="space-y-1">
                  <div className="flex justify-between text-xs font-medium">
                    <span className="text-brand-text">{sc.school}</span>
                    <span className="text-brand-muted">{sc.count.toLocaleString('fa-IR')} رزرو</span>
                  </div>
                  <div className="w-full h-2.5 bg-brand-light rounded-full overflow-hidden">
                    <div 
                      className="h-full bg-brand-primary rounded-full transition-all duration-500" 
                      style={{ width: `${pct}%` }}
                    ></div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Recent Activity Table */}
        <div className="bg-white p-5 rounded-card border border-brand-border shadow-soft">
          <h3 className="text-sm font-bold text-brand-dark mb-4">آخرین رخدادها و رزروهای ثبت‌شده</h3>
          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead>
                <tr className="border-b border-brand-border text-brand-muted pb-2">
                  <th className="pb-2 font-semibold">مدرسه</th>
                  <th className="pb-2 font-semibold">رزروکننده</th>
                  <th className="pb-2 font-semibold">تاریخ و زمان</th>
                  <th className="pb-2 font-semibold text-center">وضعیت</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-brand-border">
                {stats.recent_activity.map((act) => (
                  <tr key={act.id} className="hover:bg-brand-light transition-colors">
                    <td className="py-2.5 font-medium text-brand-dark">{act.school}</td>
                    <td className="py-2.5 text-brand-text">{act.user}</td>
                    <td className="py-2.5 text-brand-muted">{act.date} ({act.time})</td>
                    <td className="py-2.5 text-center">
                      <span className={`px-2 py-0.5 rounded-full text-[11px] font-semibold ${
                        act.status === 'تأیید شده' 
                          ? 'bg-brand-pastel text-brand-dark' 
                          : 'bg-res-red text-res-redText'
                      }`}>
                        {act.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

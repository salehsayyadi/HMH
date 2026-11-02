import React, { useState, useEffect } from 'react';
import { ShieldAlert, Plus, Unlock, Check, X, AlertCircle, Clock, Calendar } from 'lucide-react';
import { apiRequest, Restriction, TimeSlot } from '../services/api';

const fallbackRestrictions: Restriction[] = [
  {
    id: 1,
    restriction_type: 'date_range',
    start_date: '2027-01-02',
    end_date: '2027-01-20',
    jalali_start_date: '۱۲ دی ۱۴۰۵',
    jalali_end_date: '۳۰ دی ۱۴۰۵',
    reason: 'برگزاری امتحانات نوبت اول مدارس و آماده‌سازی سالن برای حوزه‌های آزمون',
    created_by_name: 'مدیر کل سامانه',
    is_active: true,
    created_at: new Date().toISOString()
  },
  {
    id: 2,
    restriction_type: 'single_slot',
    start_date: '2026-11-20',
    end_date: '2026-11-20',
    jalali_start_date: '۲۹ آبان ۱۴۰۵',
    jalali_end_date: '۲۹ آبان ۱۴۰۵',
    time_slot_id: 3,
    time_slot_title: 'ظهر (۱۲:۳۰ تا ۱۴:۳۰)',
    reason: 'سرویس دوره‌ای سیستم‌های صوت و تصویر و نورپردازی آمفی‌تئاتر',
    created_by_name: 'مدیر کل سامانه',
    is_active: true,
    created_at: new Date().toISOString()
  }
];

export const RestrictionManagementSection: React.FC = () => {
  const [restrictions, setRestrictions] = useState<Restriction[]>([]);
  const [slots, setSlots] = useState<TimeSlot[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [isOfflinePreview, setIsOfflinePreview] = useState(false);

  const [showAddModal, setShowAddModal] = useState(false);
  const [formData, setFormData] = useState({
    restriction_type: 'single_slot',
    start_date: '',
    time_slot_id: '',
    reason: ''
  });

  const loadData = async () => {
    try {
      setLoading(true);
      const [rData, sData] = await Promise.all([
        apiRequest<Restriction[]>('/restrictions'),
        apiRequest<TimeSlot[]>('/time-slots')
      ]);
      setRestrictions(rData);
      setSlots(sData);
      setIsOfflinePreview(false);
    } catch {
      setRestrictions(fallbackRestrictions);
      setSlots([
        { id: 1, slot_number: 1, title: 'صبح اول', start_time: '08:00', end_time: '10:00', is_active: true },
        { id: 2, slot_number: 2, title: 'صبح دوم', start_time: '10:00', end_time: '12:00', is_active: true },
        { id: 3, slot_number: 3, title: 'ظهر', start_time: '12:30', end_time: '14:30', is_active: true },
        { id: 4, slot_number: 4, title: 'عصر اول', start_time: '15:00', end_time: '17:00', is_active: true },
        { id: 5, slot_number: 5, title: 'عصر دوم', start_time: '18:00', end_time: '20:00', is_active: true },
      ]);
      setIsOfflinePreview(true);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setError(null);
      await apiRequest('/restrictions', {
        method: 'POST',
        body: JSON.stringify({
          restriction_type: formData.restriction_type,
          start_date: formData.start_date,
          time_slot_id: formData.time_slot_id ? Number(formData.time_slot_id) : null,
          reason: formData.reason
        })
      });
      setShowAddModal(false);
      setSuccessMsg('محدودیت زمانی با موفقیت اعمال شد.');
      setFormData({ restriction_type: 'single_slot', start_date: '', time_slot_id: '', reason: '' });
      loadData();
    } catch (err: any) {
      setError(err.message || 'خطا در اعمال محدودیت');
    }
  };

  const handleUnlock = async (id: number) => {
    try {
      setError(null);
      await apiRequest(`/restrictions/${id}`, { method: 'DELETE' });
      setSuccessMsg('محدودیت با موفقیت حذف و سانس‌ها آزاد شدند.');
      loadData();
    } catch (err: any) {
      setError(err.message || 'خطا در حذف محدودیت');
    }
  };

  const typeLabels: Record<string, string> = {
    single_slot: 'یک سانس خاص',
    day: 'یک روز کامل',
    week: 'یک هفته کامل',
    month: 'یک ماه کامل',
    global: 'انسداد سراسری'
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {successMsg && (
        <div className="p-4 bg-brand-pastel border border-emerald-200 text-brand-dark rounded-card flex items-center justify-between text-xs font-semibold">
          <div className="flex items-center gap-2">
            <Check size={16} className="text-brand-emerald" />
            <span>{successMsg}</span>
          </div>
          <button onClick={() => setSuccessMsg(null)}><X size={14} /></button>
        </div>
      )}
      {error && (
        <div className="p-4 bg-res-red border border-red-200 text-res-redText rounded-card flex items-center justify-between text-xs font-semibold">
          <div className="flex items-center gap-2">
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
          <button onClick={() => setError(null)}><X size={14} /></button>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-5 rounded-card border border-brand-border shadow-soft">
        <div>
          <h2 className="text-lg font-bold text-brand-dark flex items-center gap-2">
            <ShieldAlert size={20} className="text-brand-primary" />
            مدیریت محدودیت‌ها و انسداد سانس‌های سالن
          </h2>
          <p className="text-xs text-brand-muted mt-1">
            مسدودسازی سانس‌ها جهت تعمیرات، آزمون‌های سراسری، جلسات هیئت مدیره یا تعطیلی مجموعه
          </p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="flex items-center justify-center gap-2 px-4 py-2.5 bg-brand-primary hover:bg-brand-dark text-white rounded-btn text-xs font-bold shadow-soft transition-all"
        >
          <Plus size={16} />
          <span>تعریف محدودیت جدید</span>
        </button>
      </div>

      {/* Table */}
      <div className="bg-white rounded-card border border-brand-border shadow-soft overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-right text-xs">
            <thead>
              <tr className="bg-brand-light border-b border-brand-border text-brand-muted">
                <th className="py-3 px-4 font-bold">بازه تاریخی</th>
                <th className="py-3 px-4 font-bold">نوع محدودیت</th>
                <th className="py-3 px-4 font-bold">سانس مربوطه</th>
                <th className="py-3 px-4 font-bold">علت مسدودسازی</th>
                <th className="py-3 px-4 font-bold">ثبت‌کننده</th>
                <th className="py-3 px-4 font-bold text-center">عملیات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-brand-border">
              {restrictions.length === 0 ? (
                <tr>
                  <td colSpan={6} className="text-center py-10 text-brand-muted">
                    در حال حاضر هیچ محدودیت فعالی ثبت نشده است. تمام سانس‌های مجاز برای رزرو آزاد هستند.
                  </td>
                </tr>
              ) : (
                restrictions.map((r) => (
                  <tr key={r.id} className="hover:bg-brand-light transition-colors">
                    <td className="py-3 px-4 font-bold text-brand-dark">
                      {r.jalali_start_date} {r.start_date !== r.end_date ? `تا ${r.jalali_end_date}` : ''}
                    </td>
                    <td className="py-3 px-4">
                      <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-brand-light text-brand-primary border border-brand-border">
                        {typeLabels[r.restriction_type] || r.restriction_type}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-brand-text">{r.time_slot_title || 'تمام سانس‌ها'}</td>
                    <td className="py-3 px-4 text-brand-muted">{r.reason}</td>
                    <td className="py-3 px-4 text-brand-muted font-medium">{r.created_by_name}</td>
                    <td className="py-3 px-4 text-center">
                      <button
                        onClick={() => handleUnlock(r.id)}
                        title="رفع انسداد و آزادسازی"
                        className="px-2.5 py-1 text-xs font-semibold text-brand-emerald hover:bg-emerald-50 rounded-btn transition-colors border border-emerald-200 flex items-center gap-1 mx-auto"
                      >
                        <Unlock size={13} />
                        <span>آزادسازی</span>
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-modal shadow-modal border border-brand-border w-full max-w-md p-6 animate-fade-in">
            <div className="flex items-center justify-between pb-3 border-b border-brand-border">
              <h3 className="font-bold text-sm text-brand-dark flex items-center gap-2">
                <ShieldAlert size={16} className="text-brand-primary" />
                تعریف محدودیت و انسداد سانس‌ها
              </h3>
              <button onClick={() => setShowAddModal(false)} className="text-brand-muted hover:text-brand-dark">
                <X size={16} />
              </button>
            </div>
            <form onSubmit={handleCreate} className="space-y-4 mt-4">
              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">نوع محدودیت *</label>
                <select
                  value={formData.restriction_type}
                  onChange={(e) => setFormData({ ...formData, restriction_type: e.target.value })}
                  className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald"
                >
                  <option value="single_slot">مسدودسازی یک سانس خاص در یک روز</option>
                  <option value="day">مسدودسازی کل سانس‌های یک روز</option>
                  <option value="week">مسدودسازی یک هفته کامل (از تاریخ انتخابی)</option>
                  <option value="month">مسدودسازی یک ماه کامل</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">تاریخ شروع (میلادی تقویم YYYY-MM-DD) *</label>
                <input
                  type="date"
                  required
                  value={formData.start_date}
                  onChange={(e) => setFormData({ ...formData, start_date: e.target.value })}
                  className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono"
                />
              </div>

              {formData.restriction_type === 'single_slot' && (
                <div>
                  <label className="block text-xs font-semibold text-brand-text mb-1">انتخاب سانس مسدود شونده *</label>
                  <select
                    required
                    value={formData.time_slot_id}
                    onChange={(e) => setFormData({ ...formData, time_slot_id: e.target.value })}
                    className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald"
                  >
                    <option value="">انتخاب بازه زمانی...</option>
                    {slots.map((s) => (
                      <option key={s.id} value={s.id}>{s.title}</option>
                    ))}
                  </select>
                </div>
              )}

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">دلیل مسدودسازی *</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: تعمیرات سیستم صوتی و نورپردازی سالن"
                  value={formData.reason}
                  onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
                  className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald"
                />
              </div>

              <div className="flex justify-end gap-2 pt-3 border-t border-brand-border">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-4 py-2 text-xs font-semibold text-brand-muted hover:bg-brand-light rounded-btn"
                >
                  انصراف
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 text-xs font-bold text-white bg-brand-primary hover:bg-brand-dark rounded-btn shadow-soft"
                >
                  اعمال محدودیت
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

import React, { useState, useEffect } from 'react';
import { CalendarOff, Plus, Trash2, Check, X, AlertCircle, RefreshCw, Calendar } from 'lucide-react';
import { apiRequest, Holiday } from '../services/api';

export const HolidayManagementSection: React.FC = () => {
  const [holidays, setHolidays] = useState<Holiday[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const [showAddModal, setShowAddModal] = useState(false);
  const [formData, setFormData] = useState({
    holiday_date: '',
    title: '',
    is_official: true
  });

  const loadHolidays = async () => {
    try {
      setLoading(true);
      const data = await apiRequest<Holiday[]>('/holidays');
      setHolidays(data);
    } catch (err: any) {
      setError(err.message || 'خطا در بارگذاری تعطیلات');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadHolidays();
  }, []);

  const handleAddHoliday = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setError(null);
      await apiRequest('/holidays', {
        method: 'POST',
        body: JSON.stringify({
          holiday_date: formData.holiday_date,
          title: formData.title,
          is_official: formData.is_official,
          is_manual: true
        })
      });
      setShowAddModal(false);
      setSuccessMsg('تعطیلی جدید با موفقیت ثبت شد.');
      setFormData({ holiday_date: '', title: '', is_official: true });
      loadHolidays();
    } catch (err: any) {
      setError(err.message || 'خطا در ثبت روز تعطیل');
    }
  };

  const handleDelete = async (id: number) => {
    if (!window.confirm('آیا از حذف این تعطیلی اطمینان دارید؟')) return;
    try {
      setError(null);
      await apiRequest(`/holidays/${id}`, { method: 'DELETE' });
      setSuccessMsg('تعطیلی مورد نظر حذف شد.');
      loadHolidays();
    } catch (err: any) {
      setError(err.message || 'خطا در حذف تعطیلی');
    }
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
            <CalendarOff size={20} className="text-brand-primary" />
            مدیریت تعطیلات رسمی و مناسبتی
          </h2>
          <p className="text-xs text-brand-muted mt-1">
            تعطیلات به رنگ صورتی روشن (پاستلی) در تقویم نمایش داده می‌شوند اما رزرو در آنها مجاز است.
          </p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="flex items-center justify-center gap-2 px-4 py-2.5 bg-brand-primary hover:bg-brand-dark text-white rounded-btn text-xs font-bold shadow-soft transition-all"
        >
          <Plus size={16} />
          <span>افزودن تعطیلی دستی</span>
        </button>
      </div>

      {/* Table */}
      <div className="bg-white rounded-card border border-brand-border shadow-soft overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-right text-xs">
            <thead>
              <tr className="bg-brand-light border-b border-brand-border text-brand-muted">
                <th className="py-3 px-4 font-bold">تاریخ شمسی</th>
                <th className="py-3 px-4 font-bold">عنوان مناسبت / تعطیلی</th>
                <th className="py-3 px-4 font-bold">نوع تعطیلی</th>
                <th className="py-3 px-4 font-bold">منبع ثبت</th>
                <th className="py-3 px-4 font-bold text-center">عملیات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-brand-border">
              {holidays.map((h) => (
                <tr key={h.id} className="hover:bg-brand-light transition-colors">
                  <td className="py-3 px-4 font-bold text-brand-dark flex items-center gap-2">
                    <Calendar size={14} className="text-res-redText" />
                    <span>{h.jalali_date}</span>
                  </td>
                  <td className="py-3 px-4 text-brand-text font-medium">{h.title}</td>
                  <td className="py-3 px-4">
                    <span className={`px-2 py-0.5 rounded-full text-[11px] font-semibold ${
                      h.is_official ? 'bg-red-50 text-res-redText' : 'bg-blue-50 text-res-blueText'
                    }`}>
                      {h.is_official ? 'تعطیل رسمی' : 'مناسبتی'}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-brand-muted font-mono text-[11px]">
                    {h.is_manual ? 'دستی (مدیریت)' : 'تقویم رسمی کشوری'}
                  </td>
                  <td className="py-3 px-4 text-center">
                    <button
                      onClick={() => handleDelete(h.id)}
                      title="حذف تعطیلی"
                      className="p-1.5 text-brand-muted hover:text-res-redText hover:bg-red-50 rounded-btn transition-colors"
                    >
                      <Trash2 size={15} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add Holiday Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-modal shadow-modal border border-brand-border w-full max-w-sm p-6 animate-fade-in">
            <div className="flex items-center justify-between pb-3 border-b border-brand-border">
              <h3 className="font-bold text-sm text-brand-dark flex items-center gap-2">
                <CalendarOff size={16} className="text-brand-primary" />
                ثبت تعطیلی دستی جدید
              </h3>
              <button onClick={() => setShowAddModal(false)} className="text-brand-muted hover:text-brand-dark">
                <X size={16} />
              </button>
            </div>
            <form onSubmit={handleAddHoliday} className="space-y-4 mt-4">
              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">تاریخ میلادی تقویم (YYYY-MM-DD) *</label>
                <input
                  type="date"
                  required
                  value={formData.holiday_date}
                  onChange={(e) => setFormData({ ...formData, holiday_date: e.target.value })}
                  className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">عنوان مناسبت یا تعطیلی *</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: تعطیلی به مناسبت همایش استانی"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald"
                />
              </div>

              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="is_official"
                  checked={formData.is_official}
                  onChange={(e) => setFormData({ ...formData, is_official: e.target.checked })}
                  className="w-4 h-4 text-brand-primary rounded"
                />
                <label htmlFor="is_official" className="text-xs font-medium text-brand-text">
                  به عنوان تعطیل رسمی علامت‌گذاری شود
                </label>
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
                  ثبت روز تعطیل
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

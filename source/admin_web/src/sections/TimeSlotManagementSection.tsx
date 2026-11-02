import React, { useState, useEffect } from 'react';
import { Clock, Plus, Edit, ToggleLeft, ToggleRight, Check, X, AlertCircle } from 'lucide-react';
import { apiRequest, TimeSlot } from '../services/api';

export const TimeSlotManagementSection: React.FC = () => {
  const [slots, setSlots] = useState<TimeSlot[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [selectedSlot, setSelectedSlot] = useState<TimeSlot | null>(null);

  const [formData, setFormData] = useState({
    slot_number: 1,
    title: '',
    start_time: '08:00',
    end_time: '10:00',
    is_active: true
  });

  const loadSlots = async () => {
    try {
      setLoading(true);
      const data = await apiRequest<TimeSlot[]>('/time-slots');
      setSlots(data);
    } catch (err: any) {
      setError(err.message || 'خطا در بارگذاری بازه‌های زمانی');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSlots();
  }, []);

  const handleToggleActive = async (slot: TimeSlot) => {
    try {
      setError(null);
      await apiRequest(`/time-slots/${slot.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ is_active: !slot.is_active })
      });
      setSuccessMsg(`بازه زمانی "${slot.title}" ${slot.is_active ? 'غیرفعال' : 'فعال'} شد.`);
      loadSlots();
    } catch (err: any) {
      setError(err.message || 'خطا در تغییر وضعیت');
    }
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setError(null);
      await apiRequest('/time-slots', {
        method: 'POST',
        body: JSON.stringify({
          ...formData,
          slot_number: Number(formData.slot_number)
        })
      });
      setShowAddModal(false);
      setSuccessMsg('بازه زمانی جدید با موفقیت اضافه شد.');
      loadSlots();
    } catch (err: any) {
      setError(err.message || 'خطا در ایجاد بازه زمانی');
    }
  };

  const handleEdit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedSlot) return;
    try {
      setError(null);
      await apiRequest(`/time-slots/${selectedSlot.id}`, {
        method: 'PATCH',
        body: JSON.stringify({
          title: formData.title,
          start_time: formData.start_time,
          end_time: formData.end_time
        })
      });
      setShowEditModal(false);
      setSuccessMsg('بازه زمانی با موفقیت ویرایش شد.');
      loadSlots();
    } catch (err: any) {
      setError(err.message || 'خطا در ویرایش بازه زمانی');
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
            <Clock size={20} className="text-brand-primary" />
            مدیریت ساعت‌ها و سانس‌های رزرو سالن
          </h2>
          <p className="text-xs text-brand-muted mt-1">
            تنظیم ۵ بازه زمانی استاندارد (۰۸:۰۰ تا ۱۸:۰۰) و مدیریت فعال/غیرفعال بودن سانس‌ها
          </p>
        </div>
        <button
          onClick={() => {
            setFormData({
              slot_number: slots.length + 1,
              title: '',
              start_time: '18:00',
              end_time: '20:00',
              is_active: true
            });
            setShowAddModal(true);
          }}
          className="flex items-center justify-center gap-2 px-4 py-2.5 bg-brand-primary hover:bg-brand-dark text-white rounded-btn text-xs font-bold shadow-soft transition-all"
        >
          <Plus size={16} />
          <span>افزودن سانس جدید</span>
        </button>
      </div>

      {/* Time Slots Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4">
        {slots.map((s) => (
          <div 
            key={s.id}
            className={`p-5 bg-white rounded-card border ${s.is_active ? 'border-brand-border' : 'border-gray-200 opacity-60'} shadow-soft flex flex-col justify-between`}
          >
            <div>
              <div className="flex items-center justify-between mb-3">
                <span className="w-6 h-6 rounded-full bg-brand-light text-brand-primary flex items-center justify-center font-bold text-xs">
                  {s.slot_number}
                </span>
                <span className={`px-2 py-0.5 rounded-full text-[11px] font-bold ${
                  s.is_active ? 'bg-brand-pastel text-brand-dark' : 'bg-res-gray text-res-grayText'
                }`}>
                  {s.is_active ? 'فعال' : 'غیرفعال'}
                </span>
              </div>
              <h3 className="font-bold text-sm text-brand-dark">{s.title}</h3>
              <p className="text-xs text-brand-muted font-mono mt-1">
                {s.start_time} الی {s.end_time}
              </p>
            </div>

            <div className="mt-4 pt-3 border-t border-brand-border flex items-center justify-between">
              <button
                onClick={() => {
                  setSelectedSlot(s);
                  setFormData({
                    slot_number: s.slot_number,
                    title: s.title,
                    start_time: s.start_time,
                    end_time: s.end_time,
                    is_active: s.is_active
                  });
                  setShowEditModal(true);
                }}
                className="p-1.5 text-brand-muted hover:text-brand-primary hover:bg-brand-light rounded-btn transition-colors"
                title="ویرایش سانس"
              >
                <Edit size={15} />
              </button>
              <button
                onClick={() => handleToggleActive(s)}
                className="p-1.5 text-brand-muted hover:text-brand-dark hover:bg-brand-light rounded-btn transition-colors"
                title={s.is_active ? 'غیرفعال‌سازی' : 'فعال‌سازی'}
              >
                {s.is_active ? <ToggleRight size={18} className="text-brand-primary" /> : <ToggleLeft size={18} />}
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Add / Edit Modal */}
      {(showAddModal || showEditModal) && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-modal shadow-modal border border-brand-border w-full max-w-sm p-6 animate-fade-in">
            <div className="flex items-center justify-between pb-3 border-b border-brand-border">
              <h3 className="font-bold text-sm text-brand-dark flex items-center gap-2">
                <Clock size={16} className="text-brand-primary" />
                {showAddModal ? 'تعریف سانس زمانی جدید' : 'ویرایش مشخصات سانس'}
              </h3>
              <button 
                onClick={() => { setShowAddModal(false); setShowEditModal(false); }}
                className="text-brand-muted hover:text-brand-dark"
              >
                <X size={16} />
              </button>
            </div>
            <form onSubmit={showAddModal ? handleCreate : handleEdit} className="space-y-4 mt-4">
              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">عنوان نمایشی بازه *</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: ۱۶:۰۰ تا ۱۸:۰۰"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-brand-text mb-1">ساعت شروع *</label>
                  <input
                    type="time"
                    required
                    value={formData.start_time}
                    onChange={(e) => setFormData({ ...formData, start_time: e.target.value })}
                    className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-center"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-brand-text mb-1">ساعت پایان *</label>
                  <input
                    type="time"
                    required
                    value={formData.end_time}
                    onChange={(e) => setFormData({ ...formData, end_time: e.target.value })}
                    className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-center"
                  />
                </div>
              </div>

              <div className="flex justify-end gap-2 pt-3 border-t border-brand-border">
                <button
                  type="button"
                  onClick={() => { setShowAddModal(false); setShowEditModal(false); }}
                  className="px-4 py-2 text-xs font-semibold text-brand-muted hover:bg-brand-light rounded-btn"
                >
                  انصراف
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 text-xs font-bold text-white bg-brand-primary hover:bg-brand-dark rounded-btn shadow-soft"
                >
                  {showAddModal ? 'افزودن سانس' : 'ذخیره تغییرات'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

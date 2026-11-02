import React, { useState, useEffect } from 'react';
import { 
  CalendarCheck, 
  Search, 
  Filter, 
  Download, 
  X, 
  AlertCircle, 
  Check, 
  Eye, 
  Ban,
  Clock,
  Calendar,
  User,
  School,
  Phone
} from 'lucide-react';
import { apiRequest, Reservation, School as SchoolType, API_BASE_URL, getAccessToken } from '../services/api';

export const ReservationManagementSection: React.FC = () => {
  const [reservations, setReservations] = useState<Reservation[]>([]);
  const [schools, setSchools] = useState<SchoolType[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedSchool, setSelectedSchool] = useState<string>('');
  const [selectedStatus, setSelectedStatus] = useState<string>('');
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  // Modals
  const [detailModal, setDetailModal] = useState<Reservation | null>(null);
  const [cancelModal, setCancelModal] = useState<Reservation | null>(null);
  const [cancelReason, setCancelReason] = useState('');

  const loadData = async () => {
    try {
      setLoading(true);
      const [rData, sData] = await Promise.all([
        apiRequest<Reservation[]>('/reservations'),
        apiRequest<SchoolType[]>('/schools')
      ]);
      setReservations(rData);
      setSchools(sData);
    } catch (err: any) {
      setError(err.message || 'خطا در بارگذاری رزروها');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleCancelReservation = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!cancelModal) return;
    try {
      setError(null);
      await apiRequest(`/reservations/${cancelModal.id}/cancel`, {
        method: 'POST',
        body: JSON.stringify({ reason: cancelReason })
      });
      setCancelModal(null);
      setCancelReason('');
      setSuccessMsg(`رزرو شماره ${cancelModal.id} با موفقیت لغو و زمان آن آزاد شد.`);
      loadData();
    } catch (err: any) {
      setError(err.message || 'خطا در لغو رزرو');
    }
  };

  const handleExportExcel = () => {
    const token = getAccessToken();
    const url = `${API_BASE_URL}/reports/reservations/excel`;
    // Create an authenticated download link
    fetch(url, {
      headers: { Authorization: `Bearer ${token}` }
    })
    .then(response => response.blob())
    .then(blob => {
      const downloadUrl = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = downloadUrl;
      a.download = `amphitheater_reservations_${new Date().toISOString().slice(0, 10)}.xlsx`;
      document.body.appendChild(a);
      a.click();
      a.remove();
    })
    .catch(() => setError('خطا در دریافت فایل اکسل'));
  };

  const filtered = reservations.filter((r) => {
    const matchesSearch = 
      r.user_full_name.includes(searchTerm) || 
      r.school_name.includes(searchTerm) || 
      (r.description && r.description.includes(searchTerm));
    const matchesSchool = !selectedSchool || r.school_id.toString() === selectedSchool;
    const matchesStatus = !selectedStatus || r.status === selectedStatus;
    return matchesSearch && matchesSchool && matchesStatus;
  });

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
            <CalendarCheck size={20} className="text-brand-primary" />
            مدیریت جامع رزروهای آمفی‌تئاتر
          </h2>
          <p className="text-xs text-brand-muted mt-1">
            مشاهده، جستجو، فیلتر، لغو اضطراری و دریافت خروجی اکسل با استانداردهای رسمی
          </p>
        </div>
        <button
          onClick={handleExportExcel}
          className="flex items-center justify-center gap-2 px-4 py-2.5 bg-brand-light hover:bg-brand-pastel text-brand-dark border border-brand-border rounded-btn text-xs font-bold transition-all shadow-sm"
        >
          <Download size={16} className="text-brand-primary" />
          <span>خروجی اکسل رزروها</span>
        </button>
      </div>

      {/* Filter Bar */}
      <div className="flex flex-col md:flex-row gap-3 bg-white p-4 rounded-card border border-brand-border shadow-soft">
        <div className="flex-1 relative">
          <Search size={16} className="absolute right-3.5 top-3 text-brand-muted" />
          <input
            type="text"
            placeholder="جستجو بر اساس نام مدرسه، متقاضی یا توضیحات..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pr-10 pl-4 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald"
          />
        </div>
        <div className="w-full md:w-56">
          <select
            value={selectedSchool}
            onChange={(e) => setSelectedSchool(e.target.value)}
            className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald text-brand-text font-medium"
          >
            <option value="">همه مدارس</option>
            {schools.map((sc) => (
              <option key={sc.id} value={sc.id}>{sc.name}</option>
            ))}
          </select>
        </div>
        <div className="w-full md:w-44">
          <select
            value={selectedStatus}
            onChange={(e) => setSelectedStatus(e.target.value)}
            className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald text-brand-text font-medium"
          >
            <option value="">همه وضعیت‌ها</option>
            <option value="confirmed">تأیید شده</option>
            <option value="cancelled">لغو شده</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-card border border-brand-border shadow-soft overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-right text-xs">
            <thead>
              <tr className="bg-brand-light border-b border-brand-border text-brand-muted">
                <th className="py-3 px-4 font-bold">شناسه</th>
                <th className="py-3 px-4 font-bold">تاریخ رزرو (شمسی)</th>
                <th className="py-3 px-4 font-bold">بازه زمانی</th>
                <th className="py-3 px-4 font-bold">مدرسه</th>
                <th className="py-3 px-4 font-bold">نام رزروکننده</th>
                <th className="py-3 px-4 font-bold text-center">وضعیت</th>
                <th className="py-3 px-4 font-bold text-center">عملیات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-brand-border">
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={7} className="text-center py-10 text-brand-muted">
                    رزروی با این مشخصات یافت نشد.
                  </td>
                </tr>
              ) : (
                filtered.map((r) => (
                  <tr key={r.id} className="hover:bg-brand-light transition-colors">
                    <td className="py-3 px-4 font-mono text-brand-muted">#{r.id}</td>
                    <td className="py-3 px-4 font-semibold text-brand-dark">{r.jalali_date}</td>
                    <td className="py-3 px-4 text-brand-text">{r.time_slot?.title}</td>
                    <td className="py-3 px-4 font-medium text-brand-dark">{r.school_name}</td>
                    <td className="py-3 px-4 text-brand-text">{r.user_full_name}</td>
                    <td className="py-3 px-4 text-center">
                      <span className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                        r.status === 'confirmed' 
                          ? 'bg-brand-pastel text-brand-dark' 
                          : 'bg-res-red text-res-redText'
                      }`}>
                        {r.status === 'confirmed' ? 'تأیید شده' : 'لغو شده'}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <div className="flex items-center justify-center gap-1.5">
                        <button
                          onClick={() => setDetailModal(r)}
                          title="مشاهده جزئیات کامل"
                          className="p-1.5 text-brand-muted hover:text-brand-primary hover:bg-brand-light rounded-btn transition-colors"
                        >
                          <Eye size={15} />
                        </button>
                        {r.status === 'confirmed' && (
                          <button
                            onClick={() => setCancelModal(r)}
                            title="لغو رزرو"
                            className="p-1.5 text-brand-muted hover:text-res-redText hover:bg-red-50 rounded-btn transition-colors"
                          >
                            <Ban size={15} />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Details Modal */}
      {detailModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-modal shadow-modal border border-brand-border w-full max-w-md p-6 animate-fade-in">
            <div className="flex items-center justify-between pb-3 border-b border-brand-border">
              <h3 className="font-bold text-base text-brand-dark flex items-center gap-2">
                <CalendarCheck size={18} className="text-brand-primary" />
                مشخصات کامل رزرو شماره #{detailModal.id}
              </h3>
              <button onClick={() => setDetailModal(null)} className="text-brand-muted hover:text-brand-dark">
                <X size={18} />
              </button>
            </div>
            
            <div className="space-y-3 mt-4 text-xs">
              <div className="p-3 bg-brand-light rounded-card border border-brand-border space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-brand-muted flex items-center gap-1"><Calendar size={13} /> تاریخ رزرو:</span>
                  <span className="font-bold text-brand-dark">{detailModal.jalali_date}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-brand-muted flex items-center gap-1"><Clock size={13} /> بازه زمانی:</span>
                  <span className="font-bold text-brand-text">{detailModal.time_slot?.title}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-brand-muted flex items-center gap-1"><School size={13} /> مدرسه:</span>
                  <span className="font-bold text-brand-dark">{detailModal.school_name}</span>
                </div>
              </div>

              <div className="p-3 bg-brand-light rounded-card border border-brand-border space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-brand-muted flex items-center gap-1"><User size={13} /> متقاضی رزرو:</span>
                  <span className="font-bold text-brand-dark">{detailModal.user_full_name}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-brand-muted">سمت سازمانی:</span>
                  <span className="text-brand-text">{detailModal.position_title || 'نامشخص'}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-brand-muted flex items-center gap-1"><Phone size={13} /> شماره تماس:</span>
                  <span className="font-mono text-brand-primary font-bold">{detailModal.phone_number || 'محرمانه'}</span>
                </div>
              </div>

              {detailModal.description && (
                <div className="p-3 bg-white rounded-card border border-brand-border">
                  <span className="text-brand-muted font-semibold block mb-1">توضیحات و هدف برنامه:</span>
                  <p className="text-brand-text leading-relaxed">{detailModal.description}</p>
                </div>
              )}
            </div>

            <div className="flex justify-end pt-4 mt-2 border-t border-brand-border">
              <button
                onClick={() => setDetailModal(null)}
                className="px-5 py-2 text-xs font-bold text-white bg-brand-primary rounded-btn hover:bg-brand-dark"
              >
                بستن پنجره
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Cancel Confirmation Modal */}
      {cancelModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-modal shadow-modal border border-brand-border w-full max-w-sm p-6 animate-fade-in">
            <h3 className="font-bold text-sm text-res-redText flex items-center gap-2 mb-2">
              <Ban size={18} />
              تأیید لغو رزرو
            </h3>
            <p className="text-xs text-brand-muted mb-3 leading-relaxed">
              آیا از لغو رزرو مدرسه <strong className="text-brand-dark">{cancelModal.school_name}</strong> در تاریخ <strong className="text-brand-dark">{cancelModal.jalali_date}</strong> اطمینان دارید؟ با لغو، زمان مورد نظر برای سایرین بلافاصله آزاد خواهد شد.
            </p>
            <form onSubmit={handleCancelReservation} className="space-y-3">
              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">دلیل لغو رزرو (اختیاری):</label>
                <textarea
                  rows={2}
                  value={cancelReason}
                  onChange={(e) => setCancelReason(e.target.value)}
                  placeholder="علت لغو جهت درج در سوابق سیستم..."
                  className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald"
                />
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setCancelModal(null)}
                  className="px-4 py-2 text-xs font-semibold text-brand-muted hover:bg-brand-light rounded-btn"
                >
                  انصراف
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 text-xs font-bold text-white bg-res-redText hover:bg-red-800 rounded-btn"
                >
                  لغو قطعی رزرو
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

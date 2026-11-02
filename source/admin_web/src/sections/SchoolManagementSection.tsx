import React, { useState, useEffect } from 'react';
import { 
  School, 
  Plus, 
  Edit, 
  Users, 
  CalendarCheck, 
  Check, 
  X, 
  AlertCircle,
  ToggleLeft,
  ToggleRight
} from 'lucide-react';
import { apiRequest, School as SchoolType } from '../services/api';

const initialOfficialSchools: SchoolType[] = [
  { id: 1, name: 'دبستان دخترانه امام حسین (ع)', code: 'SCH-101', description: 'دبستان دخترانه تابعه موسسه خیریه فرهنگی آموزشی حضرت امام حسین (ع) یزد', is_active: true, user_count: 1, reservation_count: 11, created_at: new Date().toISOString() },
  { id: 2, name: 'دبستان پسرانه امام حسین (ع)', code: 'SCH-102', description: 'دبستان پسرانه تابعه موسسه خیریه فرهنگی آموزشی حضرت امام حسین (ع) یزد', is_active: true, user_count: 1, reservation_count: 14, created_at: new Date().toISOString() },
  { id: 3, name: 'دبیرستان دخترانه دوره اول امام حسین (ع)', code: 'SCH-201', description: 'دبیرستان دخترانه دوره اول تابعه موسسه امام حسین (ع) یزد', is_active: true, user_count: 1, reservation_count: 12, created_at: new Date().toISOString() },
  { id: 4, name: 'دبیرستان پسرانه دوره اول امام حسین (ع)', code: 'SCH-202', description: 'دبیرستان پسرانه دوره اول تابعه موسسه امام حسین (ع) یزد', is_active: true, user_count: 1, reservation_count: 7, created_at: new Date().toISOString() },
  { id: 5, name: 'دبیرستان دخترانه دوره دوم امام حسین (ع)', code: 'SCH-301', description: 'دبیرستان دخترانه دوره دوم تابعه موسسه امام حسین (ع) یزد', is_active: true, user_count: 1, reservation_count: 8, created_at: new Date().toISOString() },
  { id: 6, name: 'دبیرستان پسرانه دوره دوم امام حسین (ع)', code: 'SCH-302', description: 'دبیرستان پسرانه دوره دوم تابعه موسسه امام حسین (ع) یزد', is_active: true, user_count: 1, reservation_count: 15, created_at: new Date().toISOString() },
];

export const SchoolManagementSection: React.FC = () => {
  const [schools, setSchools] = useState<SchoolType[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [isOfflinePreview, setIsOfflinePreview] = useState(false);

  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [selectedSchool, setSelectedSchool] = useState<SchoolType | null>(null);

  const [formData, setFormData] = useState({
    name: '',
    code: '',
    description: '',
    is_active: true
  });

  const loadSchools = async () => {
    try {
      setLoading(true);
      const data = await apiRequest<SchoolType[]>('/schools?include_inactive=true');
      setSchools(data);
      setIsOfflinePreview(false);
    } catch {
      setSchools(initialOfficialSchools);
      setIsOfflinePreview(true);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSchools();
  }, []);

  const handleCreateSchool = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setError(null);
      await apiRequest('/schools', {
        method: 'POST',
        body: JSON.stringify(formData)
      });
      setShowAddModal(false);
      setSuccessMsg('مدرسه جدید با موفقیت اضافه شد.');
      setFormData({ name: '', code: '', description: '', is_active: true });
      loadSchools();
    } catch (err: any) {
      setError(err.message || 'خطا در ثبت مدرسه');
    }
  };

  const handleUpdateSchool = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedSchool) return;
    try {
      setError(null);
      await apiRequest(`/schools/${selectedSchool.id}`, {
        method: 'PATCH',
        body: JSON.stringify(formData)
      });
      setShowEditModal(false);
      setSuccessMsg(`اطلاعات ${formData.name} با موفقیت ویرایش شد.`);
      loadSchools();
    } catch (err: any) {
      setError(err.message || 'خطا در ویرایش مدرسه');
    }
  };

  const handleToggleActive = async (school: SchoolType) => {
    try {
      setError(null);
      await apiRequest(`/schools/${school.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ is_active: !school.is_active })
      });
      setSuccessMsg(`وضعیت مدرسه "${school.name}" تغییر یافت.`);
      loadSchools();
    } catch (err: any) {
      setError(err.message || 'خطا در تغییر وضعیت');
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
            <School size={20} className="text-brand-primary" />
            مدیریت مدارس موسسه حضرت امام حسین (ع)
          </h2>
          <p className="text-xs text-brand-muted mt-1">
            تعریف شعب جدید، ویرایش اطلاعات، مدیریت دسترسی‌ها و مشاهده آمار عملکرد مدارس
          </p>
        </div>
        <button
          onClick={() => {
            setFormData({ name: '', code: '', description: '', is_active: true });
            setShowAddModal(true);
          }}
          className="flex items-center justify-center gap-2 px-4 py-2.5 bg-brand-primary hover:bg-brand-dark text-white rounded-btn text-xs font-bold shadow-soft transition-all"
        >
          <Plus size={16} />
          <span>افزودن مدرسه جدید</span>
        </button>
      </div>

      {/* Schools Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {schools.map((sc) => (
          <div 
            key={sc.id} 
            className={`p-5 bg-white rounded-card border ${sc.is_active ? 'border-brand-border' : 'border-gray-200 opacity-75'} shadow-soft flex flex-col justify-between transition-all`}
          >
            <div>
              <div className="flex items-start justify-between gap-2 mb-3">
                <div className="p-2 rounded-xl bg-brand-light text-brand-primary">
                  <School size={22} />
                </div>
                <span className={`px-2 py-0.5 rounded-full text-[11px] font-bold ${
                  sc.is_active ? 'bg-brand-pastel text-brand-dark' : 'bg-res-gray text-res-grayText'
                }`}>
                  {sc.is_active ? 'فعال' : 'غیرفعال'}
                </span>
              </div>
              <h3 className="font-bold text-sm text-brand-dark">{sc.name}</h3>
              {sc.code && <span className="text-[11px] font-mono text-brand-muted">کد شناسه: {sc.code}</span>}
              <p className="text-xs text-brand-muted mt-2 line-clamp-2">
                {sc.description || 'مدرسه تابعه موسسه خیریه فرهنگی آموزشی حضرت امام حسین (ع)'}
              </p>
            </div>

            <div className="mt-5 pt-4 border-t border-brand-border flex items-center justify-between">
              <div className="flex items-center gap-4 text-xs text-brand-muted">
                <span className="flex items-center gap-1">
                  <Users size={14} className="text-brand-secondary" />
                  {sc.user_count || 0} کاربر
                </span>
                <span className="flex items-center gap-1">
                  <CalendarCheck size={14} className="text-brand-emerald" />
                  {sc.reservation_count || 0} رزرو
                </span>
              </div>
              <div className="flex items-center gap-1">
                <button
                  onClick={() => {
                    setSelectedSchool(sc);
                    setFormData({
                      name: sc.name,
                      code: sc.code || '',
                      description: sc.description || '',
                      is_active: sc.is_active
                    });
                    setShowEditModal(true);
                  }}
                  className="p-1.5 text-brand-muted hover:text-brand-primary hover:bg-brand-light rounded-btn transition-colors"
                  title="ویرایش مشخصات"
                >
                  <Edit size={15} />
                </button>
                <button
                  onClick={() => handleToggleActive(sc)}
                  className="p-1.5 text-brand-muted hover:text-brand-dark hover:bg-brand-light rounded-btn transition-colors"
                  title={sc.is_active ? 'غیرفعال‌سازی' : 'فعال‌سازی'}
                >
                  {sc.is_active ? <ToggleRight size={18} className="text-brand-primary" /> : <ToggleLeft size={18} />}
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Modal Add/Edit */}
      {(showAddModal || showEditModal) && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-modal shadow-modal border border-brand-border w-full max-w-md p-6 animate-fade-in">
            <div className="flex items-center justify-between pb-4 border-b border-brand-border">
              <h3 className="font-bold text-base text-brand-dark flex items-center gap-2">
                <School size={18} className="text-brand-primary" />
                {showAddModal ? 'تعریف و ثبت مدرسه جدید' : 'ویرایش مشخصات مدرسه'}
              </h3>
              <button 
                onClick={() => { setShowAddModal(false); setShowEditModal(false); }}
                className="text-brand-muted hover:text-brand-dark"
              >
                <X size={18} />
              </button>
            </div>
            <form onSubmit={showAddModal ? handleCreateSchool : handleUpdateSchool} className="space-y-4 mt-4">
              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">نام کامل مدرسه *</label>
                <input
                  type="text"
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="مثال: مدرسه دخترانه دوره دوم"
                  className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">کد شناسه مدرسه</label>
                <input
                  type="text"
                  value={formData.code}
                  onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                  placeholder="مثال: SCH-G2"
                  className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald text-left font-mono"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">توضیحات</label>
                <textarea
                  rows={3}
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  placeholder="آدرس، شماره تماس یا توضیحات تکمیلی..."
                  className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald"
                />
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t border-brand-border">
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
                  {showAddModal ? 'ثبت مدرسه' : 'ذخیره تغییرات'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

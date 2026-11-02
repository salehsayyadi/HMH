import React, { useState, useEffect } from 'react';
import { 
  Users, 
  UserPlus, 
  Search, 
  Filter, 
  Edit, 
  KeyRound, 
  UserX, 
  UserCheck, 
  X,
  Check,
  AlertCircle
} from 'lucide-react';
import { apiRequest, User, School } from '../services/api';

const offlineSchools: School[] = [
  { id: 1, name: 'دبستان دخترانه امام حسین (ع)', code: 'SCH-101', description: 'دبستان دخترانه تابعه موسسه خیریه فرهنگی آموزشی امام حسین (ع)', is_active: true, user_count: 1, reservation_count: 11, created_at: new Date().toISOString() },
  { id: 2, name: 'دبستان پسرانه امام حسین (ع)', code: 'SCH-102', description: 'دبستان پسرانه تابعه موسسه خیریه فرهنگی آموزشی امام حسین (ع)', is_active: true, user_count: 1, reservation_count: 14, created_at: new Date().toISOString() },
  { id: 3, name: 'دبیرستان دخترانه دوره اول امام حسین (ع)', code: 'SCH-201', description: 'دبیرستان دوره اول دخترانه تابعه موسسه امام حسین (ع)', is_active: true, user_count: 1, reservation_count: 12, created_at: new Date().toISOString() },
  { id: 4, name: 'دبیرستان پسرانه دوره اول امام حسین (ع)', code: 'SCH-202', description: 'دبیرستان دوره اول پسرانه تابعه موسسه امام حسین (ع)', is_active: true, user_count: 1, reservation_count: 7, created_at: new Date().toISOString() },
  { id: 5, name: 'دبیرستان دخترانه دوره دوم امام حسین (ع)', code: 'SCH-301', description: 'دبیرستان دوره دوم دخترانه تابعه موسسه امام حسین (ع)', is_active: true, user_count: 1, reservation_count: 8, created_at: new Date().toISOString() },
  { id: 6, name: 'دبیرستان پسرانه دوره دوم امام حسین (ع)', code: 'SCH-302', description: 'دبیرستان دوره دوم پسرانه تابعه موسسه امام حسین (ع)', is_active: true, user_count: 1, reservation_count: 15, created_at: new Date().toISOString() },
];

const offlinePositions = [
  { id: 1, title: 'مدیر مدرسه' },
  { id: 2, title: 'معاون اجرایی' },
  { id: 3, title: 'معاون پرورشی' },
  { id: 4, title: 'معاون آموزشی' },
];

const offlineUsers: User[] = [
  {
    id: 1,
    username: '123IMHModirkol@1090',
    first_name: 'مدیر',
    last_name: 'کل سامانه',
    full_name: 'مدیر ارشد سامانه',
    role: 'super_admin',
    phone_number: '09131110000',
    school_id: undefined,
    position_id: 1,
    position: { id: 1, title: 'مدیر ارشد سیستم' },
    is_active: true,
    must_change_password: false,
    created_at: new Date().toISOString(),
    last_login: 'هم‌اکنون'
  },
  {
    id: 2,
    username: 'm.karestan',
    first_name: 'محمدمحسن',
    last_name: 'کارستان',
    full_name: 'محمدمحسن کارستان',
    role: 'user',
    phone_number: '09132510001',
    school_id: 6,
    school: { id: 6, name: 'دبیرستان پسرانه دوره دوم امام حسین (ع)' },
    position_id: 2,
    position: { id: 2, title: 'معاون اجرایی' },
    is_active: true,
    must_change_password: false,
    created_at: new Date().toISOString(),
    last_login: 'دیروز'
  },
  {
    id: 3,
    username: 'f.karimi',
    first_name: 'فاطمه',
    last_name: 'کریمی',
    full_name: 'فاطمه کریمی',
    role: 'user',
    phone_number: '09132510002',
    school_id: 1,
    school: { id: 1, name: 'دبستان دخترانه امام حسین (ع)' },
    position_id: 1,
    position: { id: 1, title: 'مدیر مدرسه' },
    is_active: true,
    must_change_password: false,
    created_at: new Date().toISOString(),
    last_login: '۲ روز پیش'
  },
  {
    id: 4,
    username: 'a.rezaei',
    first_name: 'علی',
    last_name: 'رضایی',
    full_name: 'علی رضایی',
    role: 'user',
    phone_number: '09132510003',
    school_id: 2,
    school: { id: 2, name: 'دبستان پسرانه امام حسین (ع)' },
    position_id: 2,
    position: { id: 2, title: 'معاون اجرایی' },
    is_active: true,
    must_change_password: false,
    created_at: new Date().toISOString(),
    last_login: 'امروز'
  },
  {
    id: 5,
    username: 'm.hosseini',
    first_name: 'مریم',
    last_name: 'حسینی',
    full_name: 'مریم حسینی',
    role: 'user',
    phone_number: '09132510004',
    school_id: 3,
    school: { id: 3, name: 'دبیرستان دخترانه دوره اول امام حسین (ع)' },
    position_id: 3,
    position: { id: 3, title: 'معاون پرورشی' },
    is_active: true,
    must_change_password: false,
    created_at: new Date().toISOString(),
    last_login: '۳ روز پیش'
  },
  {
    id: 6,
    username: 'h.ahmadi',
    first_name: 'حسین',
    last_name: 'احمدی',
    full_name: 'حسین احمدی',
    role: 'user',
    phone_number: '09132510005',
    school_id: 4,
    school: { id: 4, name: 'دبیرستان پسرانه دوره اول امام حسین (ع)' },
    position_id: 2,
    position: { id: 2, title: 'معاون اجرایی' },
    is_active: true,
    must_change_password: false,
    created_at: new Date().toISOString(),
    last_login: '۴ روز پیش'
  },
  {
    id: 7,
    username: 'z.akbari',
    first_name: 'زهرا',
    last_name: 'اکبری',
    full_name: 'زهرا اکبری',
    role: 'user',
    phone_number: '09132510006',
    school_id: 5,
    school: { id: 5, name: 'دبیرستان دخترانه دوره دوم امام حسین (ع)' },
    position_id: 1,
    position: { id: 1, title: 'مدیر مدرسه' },
    is_active: true,
    must_change_password: false,
    created_at: new Date().toISOString(),
    last_login: 'هفته گذشته'
  }
];

export const UserManagementSection: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [schools, setSchools] = useState<School[]>([]);
  const [positions, setPositions] = useState<{ id: number; title: string }[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedSchool, setSelectedSchool] = useState<string>('');
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [isOfflinePreview, setIsOfflinePreview] = useState(false);

  // Modal states
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showResetModal, setShowResetModal] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);

  // Form states
  const [formData, setFormData] = useState({
    first_name: '',
    last_name: '',
    username: '',
    initial_password: '',
    school_id: '',
    position_id: '',
    phone_number: '',
    role: 'user'
  });
  const [newPassword, setNewPassword] = useState('');

  const loadData = async () => {
    try {
      setLoading(true);
      const [uData, sData, pData] = await Promise.all([
        apiRequest<User[]>('/users'),
        apiRequest<School[]>('/schools'),
        apiRequest<{ id: number; title: string }[]>('/schools/positions/list')
      ]);
      setUsers(uData);
      setSchools(sData);
      setPositions(pData);
      setIsOfflinePreview(false);
    } catch {
      // Offline fallback: keep full interactive user management
      setUsers(offlineUsers);
      setSchools(offlineSchools);
      setPositions(offlinePositions);
      setIsOfflinePreview(true);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setError(null);
      await apiRequest('/users', {
        method: 'POST',
        body: JSON.stringify({
          first_name: formData.first_name,
          last_name: formData.last_name,
          username: formData.username,
          initial_password: formData.initial_password,
          school_id: Number(formData.school_id),
          position_id: formData.position_id ? Number(formData.position_id) : null,
          phone_number: formData.phone_number,
          role: formData.role
        })
      });
      setShowAddModal(false);
      setSuccessMsg('کاربر جدید با موفقیت ایجاد شد.');
      setFormData({
        first_name: '',
        last_name: '',
        username: '',
        initial_password: '',
        school_id: '',
        position_id: '',
        phone_number: '',
        role: 'user'
      });
      loadData();
    } catch (err: any) {
      setError(err.message || 'خطا در ایجاد کاربر');
    }
  };

  const handleToggleActive = async (user: User) => {
    try {
      setError(null);
      await apiRequest(`/users/${user.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ is_active: !user.is_active })
      });
      setSuccessMsg(`حساب کاربری ${user.full_name} ${user.is_active ? 'غیرفعال' : 'فعال'} شد.`);
      loadData();
    } catch (err: any) {
      setError(err.message || 'خطا در تغییر وضعیت حساب');
    }
  };

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedUser) return;
    try {
      setError(null);
      await apiRequest(`/users/${selectedUser.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ reset_password: newPassword })
      });
      setShowResetModal(false);
      setNewPassword('');
      setSuccessMsg(`رمز عبور ${selectedUser.full_name} با موفقیت بازنشانی شد.`);
    } catch (err: any) {
      setError(err.message || 'خطا در بازنشانی رمز عبور');
    }
  };

  const filteredUsers = users.filter((u) => {
    const matchesSearch = 
      u.full_name.includes(searchTerm) || 
      u.username.includes(searchTerm) || 
      (u.phone_number && u.phone_number.includes(searchTerm));
    const matchesSchool = !selectedSchool || u.school_id?.toString() === selectedSchool;
    return matchesSearch && matchesSchool;
  });

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Notifications */}
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

      {/* Header & Actions */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-5 rounded-card border border-brand-border shadow-soft">
        <div>
          <h2 className="text-lg font-bold text-brand-dark flex items-center gap-2">
            <Users size={20} className="text-brand-primary" />
            مدیریت حساب‌های کاربری مدارس
          </h2>
          <p className="text-xs text-brand-muted mt-1">
            ایجاد، ویرایش، بازنشانی کلمه عبور و کنترل دسترسی معاونین و رابطین مدارس
          </p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="flex items-center justify-center gap-2 px-4 py-2.5 bg-brand-primary hover:bg-brand-dark text-white rounded-btn text-xs font-bold shadow-soft transition-all"
        >
          <UserPlus size={16} />
          <span>تعریف کاربر جدید</span>
        </button>
      </div>

      {/* Filter Bar */}
      <div className="flex flex-col md:flex-row gap-3 bg-white p-4 rounded-card border border-brand-border shadow-soft">
        <div className="flex-1 relative">
          <Search size={16} className="absolute right-3.5 top-3 text-brand-muted" />
          <input
            type="text"
            placeholder="جستجو بر اساس نام، نام کاربری یا شماره همراه..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pr-10 pl-4 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald"
          />
        </div>
        <div className="w-full md:w-64">
          <select
            value={selectedSchool}
            onChange={(e) => setSelectedSchool(e.target.value)}
            className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald text-brand-text font-medium"
          >
            <option value="">همه مدارس ({schools.length})</option>
            {schools.map((sc) => (
              <option key={sc.id} value={sc.id}>{sc.name}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-white rounded-card border border-brand-border shadow-soft overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-right text-xs">
            <thead>
              <tr className="bg-brand-light border-b border-brand-border text-brand-muted">
                <th className="py-3 px-4 font-bold">نام و نام خانوادگی</th>
                <th className="py-3 px-4 font-bold">نام کاربری</th>
                <th className="py-3 px-4 font-bold">مدرسه منتسب</th>
                <th className="py-3 px-4 font-bold">سمت سازمانی</th>
                <th className="py-3 px-4 font-bold">شماره تماس</th>
                <th className="py-3 px-4 font-bold text-center">وضعیت حساب</th>
                <th className="py-3 px-4 font-bold text-center">عملیات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-brand-border">
              {filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={7} className="text-center py-10 text-brand-muted">
                    کاربری با این مشخصات یافت نشد.
                  </td>
                </tr>
              ) : (
                filteredUsers.map((u) => (
                  <tr key={u.id} className="hover:bg-brand-light transition-colors">
                    <td className="py-3 px-4 font-semibold text-brand-dark">
                      <div className="flex items-center gap-2">
                        <div className="w-7 h-7 rounded-full bg-brand-pastel text-brand-dark flex items-center justify-center font-bold text-xs">
                          {u.first_name[0]}
                        </div>
                        <span>{u.full_name}</span>
                      </div>
                    </td>
                    <td className="py-3 px-4 font-mono text-brand-muted text-[11px]">{u.username}</td>
                    <td className="py-3 px-4 text-brand-text">{u.school?.name || '—'}</td>
                    <td className="py-3 px-4 text-brand-muted">{u.position?.title || '—'}</td>
                    <td className="py-3 px-4 text-brand-muted">{u.phone_number || '—'}</td>
                    <td className="py-3 px-4 text-center">
                      <span className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                        u.is_active 
                          ? 'bg-brand-pastel text-brand-dark' 
                          : 'bg-res-gray text-res-grayText'
                      }`}>
                        {u.is_active ? 'فعال' : 'غیرفعال'}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <div className="flex items-center justify-center gap-1.5">
                        <button
                          onClick={() => { setSelectedUser(u); setShowResetModal(true); }}
                          title="بازنشانی رمز عبور"
                          className="p-1.5 text-brand-muted hover:text-brand-primary hover:bg-brand-light rounded-btn transition-colors"
                        >
                          <KeyRound size={15} />
                        </button>
                        <button
                          onClick={() => handleToggleActive(u)}
                          title={u.is_active ? 'غیرفعال کردن کاربر' : 'فعال‌سازی کاربر'}
                          className={`p-1.5 rounded-btn transition-colors ${
                            u.is_active 
                              ? 'text-brand-muted hover:text-res-redText hover:bg-red-50' 
                              : 'text-brand-muted hover:text-brand-primary hover:bg-green-50'
                          }`}
                        >
                          {u.is_active ? <UserX size={15} /> : <UserCheck size={15} />}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add User Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-modal shadow-modal border border-brand-border w-full max-w-lg p-6 animate-fade-in">
            <div className="flex items-center justify-between pb-4 border-b border-brand-border">
              <h3 className="font-bold text-base text-brand-dark flex items-center gap-2">
                <UserPlus size={18} className="text-brand-primary" />
                ثبت و ایجاد کاربر سازمانی جدید
              </h3>
              <button onClick={() => setShowAddModal(false)} className="text-brand-muted hover:text-brand-dark">
                <X size={18} />
              </button>
            </div>
            <form onSubmit={handleCreateUser} className="space-y-4 mt-4">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-brand-text mb-1">نام *</label>
                  <input
                    type="text"
                    required
                    value={formData.first_name}
                    onChange={(e) => setFormData({ ...formData, first_name: e.target.value })}
                    className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-brand-text mb-1">نام خانوادگی *</label>
                  <input
                    type="text"
                    required
                    value={formData.last_name}
                    onChange={(e) => setFormData({ ...formData, last_name: e.target.value })}
                    className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-brand-text mb-1">نام کاربری *</label>
                  <input
                    type="text"
                    required
                    value={formData.username}
                    onChange={(e) => setFormData({ ...formData, username: e.target.value })}
                    className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald text-left font-mono"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-brand-text mb-1">رمز عبور اولیه *</label>
                  <input
                    type="password"
                    required
                    minLength={6}
                    value={formData.initial_password}
                    onChange={(e) => setFormData({ ...formData, initial_password: e.target.value })}
                    className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald text-left font-mono"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-brand-text mb-1">مدرسه مربوطه *</label>
                  <select
                    required
                    value={formData.school_id}
                    onChange={(e) => setFormData({ ...formData, school_id: e.target.value })}
                    className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald"
                  >
                    <option value="">انتخاب مدرسه...</option>
                    {schools.map((sc) => (
                      <option key={sc.id} value={sc.id}>{sc.name}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-brand-text mb-1">سمت سازمانی</label>
                  <select
                    value={formData.position_id}
                    onChange={(e) => setFormData({ ...formData, position_id: e.target.value })}
                    className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald"
                  >
                    <option value="">انتخاب سمت...</option>
                    {positions.map((pos) => (
                      <option key={pos.id} value={pos.id}>{pos.title}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">شماره تماس همراه</label>
                <input
                  type="text"
                  placeholder="0913..."
                  value={formData.phone_number}
                  onChange={(e) => setFormData({ ...formData, phone_number: e.target.value })}
                  className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald text-left font-mono"
                />
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t border-brand-border">
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
                  ثبت کاربر
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Reset Password Modal */}
      {showResetModal && selectedUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-modal shadow-modal border border-brand-border w-full max-w-sm p-6 animate-fade-in">
            <h3 className="font-bold text-sm text-brand-dark flex items-center gap-2 mb-2">
              <KeyRound size={17} className="text-brand-primary" />
              بازنشانی رمز عبور {selectedUser.full_name}
            </h3>
            <p className="text-xs text-brand-muted mb-4">
              رمز عبور جدیدی وارد کنید. کاربر در ورود بعدی موظف به تغییر رمز خواهد بود.
            </p>
            <form onSubmit={handleResetPassword} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">کلمه عبور جدید</label>
                <input
                  type="password"
                  required
                  minLength={6}
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  className="w-full px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald text-left font-mono"
                />
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowResetModal(false)}
                  className="px-4 py-2 text-xs font-semibold text-brand-muted hover:bg-brand-light rounded-btn"
                >
                  انصراف
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 text-xs font-bold text-white bg-brand-primary hover:bg-brand-dark rounded-btn"
                >
                  تغییر رمز
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

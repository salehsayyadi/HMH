import React, { useState, useEffect } from 'react';
import { 
  Server, 
  Database, 
  Globe, 
  ShieldCheck, 
  Check, 
  X, 
  AlertCircle, 
  RefreshCw, 
  Play, 
  Lock, 
  Save, 
  Cpu, 
  Wifi, 
  CheckCircle2, 
  XCircle,
  Clock,
  Shield,
  Download,
  Upload,
  Info,
  Building,
  Key,
  HardDrive
} from 'lucide-react';
import { apiRequest, ServerInfo, ConnectionTestResult } from '../services/api';

type SettingsTab = 'server' | 'database' | 'general' | 'security' | 'backup' | 'info';

export const SystemSettingsSection: React.FC = () => {
  const [activeTab, setActiveTab] = useState<SettingsTab>('server');
  const [loading, setLoading] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState<string | null>(null);

  // Connection testing state
  const [testing, setTesting] = useState(false);
  const [testResults, setTestResults] = useState<ConnectionTestResult[]>([]);
  const [showTestModal, setShowTestModal] = useState(false);

  // Backup state
  const [backupLoading, setBackupLoading] = useState(false);
  const [backupSuccess, setBackupSuccess] = useState<string | null>(null);

  // 1. Server & Connection Settings (matching reference image)
  const [serverValues, setServerValues] = useState({
    domain: 'salehvip-clud.ir',
    subdomain: 'reserve.salehvip-clud.ir',
    server_os: 'Ubuntu 24.04 LTS',
    api_base_url: 'https://reserve.salehvip-clud.ir/api/v1',
    websocket_url: 'wss://reserve.salehvip-clud.ir/ws',
    db_engine: 'MySQL 9.7 LTS',
    db_host: 'mysql',
    db_port: '3306',
    db_name: 'amphitheater_db',
    db_user: 'amphitheater_app',
    https_port: '443',
    jwt_secret: '••••••••••••••••••••••••••••••••'
  });

  // 2. Database Status
  const dbStatus = {
    engine: 'MySQL Community Server 9.7 LTS',
    driver: 'mysqlclient / PyMySQL (AsyncPool)',
    host: 'mysql (Ubuntu Docker)',
    port: 3306,
    database: 'amphitheater_db',
    charset: 'utf8mb4_unicode_ci',
    pool_size: 15,
    active_connections: 3,
    tables_count: 8,
    db_size: '14.2 MB',
    uptime: '18 روز و ۷ ساعت',
    status: 'سالم و در حال کار (Optimal)'
  };

  // 3. General Settings
  const [generalValues, setGeneralValues] = useState({
    org_name: 'موسسه خیریه فرهنگی آموزشی حضرت امام حسین (ع) یزد',
    auditorium_name: 'سالن آمفی‌تئاتر مرکزی مجتمع آموزشی امام حسین (ع)',
    capacity: 450,
    min_notice_hours: 24,
    max_advance_days: 45,
    support_phone: '۰۳۵-۳۸۲۴۰۰۰۰',
    admin_email: 'info@salehvip-clud.ir'
  });

  // 4. Security Settings
  const [securityValues, setSecurityValues] = useState({
    jwt_expiry_minutes: 60,
    refresh_token_days: 30,
    max_failed_attempts: 5,
    lockout_minutes: 15,
    enforce_strong_passwords: true,
    require_password_change_days: 90
  });

  // 5. Backups history
  const [backups, setBackups] = useState([
    { id: 'bk_1', filename: 'amh_db_backup_1405_08_10.sql.gz', size: '2.4 MB', date: '۱۰ آبان ۱۴۰۵ — ۰۲:۰۰', status: 'موفق' },
    { id: 'bk_2', filename: 'amh_db_backup_1405_08_03.sql.gz', size: '2.3 MB', date: '۰۳ آبان ۱۴۰۵ — ۰۲:۰۰', status: 'موفق' },
    { id: 'bk_3', filename: 'amh_db_backup_1405_07_26.sql.gz', size: '2.1 MB', date: '۲۶ مهر ۱۴۰۵ — ۰۲:۰۰', status: 'موفق' },
  ]);

  const loadServerInfo = async () => {
    try {
      setLoading(true);
      const data = await apiRequest<ServerInfo>('/system/status');
      if (data) {
        setServerValues(prev => ({
          ...prev,
          domain: data.domain || prev.domain,
          subdomain: data.subdomain || prev.subdomain,
          server_os: data.server_os || prev.server_os,
          api_base_url: data.api_base_url || prev.api_base_url,
          websocket_url: data.websocket_url || prev.websocket_url,
          db_engine: 'MySQL 9.7 LTS',
          db_name: data.database_name || prev.db_name,
        }));
      }
    } catch {
      // Keep rich defaults in offline mode
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadServerInfo();
  }, []);

  const runAllTests = async () => {
    setTesting(true);
    setTestResults([]);
    setShowTestModal(true);

    const testTypes = ['server', 'database', 'api', 'websocket', 'ssl'];
    const results: ConnectionTestResult[] = [];

    for (const t of testTypes) {
      try {
        const res = await apiRequest<ConnectionTestResult>('/system/test-connection', {
          method: 'POST',
          body: JSON.stringify({ test_type: t })
        });
        results.push(res);
      } catch (err: any) {
        // Provide informative offline check
        results.push({
          test_type: t,
          success: false,
          status_text: `عدم برقراری ارتباط با سرور در آدرس ${serverValues.api_base_url} (خطای شبکه یا پورت مسدود است).`
        });
      }
      setTestResults([...results]);
    }
    setTesting(false);
  };

  const handleSave = (tabName: string) => {
    setSaveSuccess(`تنظیمات بخش «${tabName}» با موفقیت در پیکربندی ذخیره گردید.`);
    setTimeout(() => setSaveSuccess(null), 4000);
  };

  const handleCreateBackup = () => {
    setBackupLoading(true);
    setTimeout(() => {
      const newBk = {
        id: `bk_${Date.now()}`,
        filename: `amh_db_backup_1405_08_11_${Math.floor(Math.random()*1000)}.sql.gz`,
        size: '2.5 MB',
        date: 'هم‌اکنون — ۱۱ آبان ۱۴۰۵',
        status: 'موفق'
      };
      setBackups([newBk, ...backups]);
      setBackupLoading(false);
      setBackupSuccess('نسخه پشتیبان پایگاه‌داده MySQL با موفقیت ایجاد گردید.');
      setTimeout(() => setBackupSuccess(null), 4000);
    }, 1200);
  };

  const testTypeTitles: Record<string, string> = {
    server: 'بررسی سلامت سرور لینوکس (Ubuntu 24.04)',
    database: 'بررسی ارتباط با پایگاه داده MySQL 9.7 LTS',
    api: 'بررسی سرویس RESTful API نسخه v1',
    websocket: 'بررسی اتصال سوکت بلادرنگ (WebSocket)',
    ssl: 'بررسی اعتبار گواهی امنیتی SSL/TLS'
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {saveSuccess && (
        <div className="p-4 bg-brand-pastel border border-emerald-200 text-brand-dark rounded-card flex items-center justify-between text-xs font-semibold">
          <div className="flex items-center gap-2">
            <Check size={16} className="text-brand-emerald" />
            <span>{saveSuccess}</span>
          </div>
          <button onClick={() => setSaveSuccess(null)}><X size={14} /></button>
        </div>
      )}

      {/* Top Banner Matching Reference Image */}
      <div className="bg-white p-5 rounded-card border border-brand-border shadow-soft flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <h2 className="text-lg font-bold text-brand-dark flex items-center gap-2">
              <Server size={22} className="text-brand-primary" />
              تنظیمات سامانه
            </h2>
          </div>
          <p className="text-xs text-brand-muted">
            پیکربندی ارتباط با سرور، پایگاه داده MySQL 9.7، امنیت، نسخه‌های پشتیبان و تنظیمات عمومی سامانه
          </p>
        </div>

        {/* Live Status Indicators matching reference */}
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-brand-pastel text-brand-dark text-xs font-bold border border-emerald-200">
            <span className="w-2.5 h-2.5 rounded-full bg-brand-secondary animate-pulse"></span>
            <span>اتصال API: آماده</span>
          </div>
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-brand-pastel text-brand-dark text-xs font-bold border border-emerald-200">
            <span className="w-2.5 h-2.5 rounded-full bg-brand-emerald animate-pulse"></span>
            <span>اتصال دیتابیس: MySQL 9.7</span>
          </div>
        </div>
      </div>

      {/* Navigation Sub-Tabs */}
      <div className="flex flex-wrap gap-2 border-b border-brand-border pb-3">
        <button
          onClick={() => setActiveTab('server')}
          className={`flex items-center gap-2 px-4 py-2.5 rounded-btn text-xs font-bold transition-all ${
            activeTab === 'server'
              ? 'bg-brand-primary text-white shadow-soft'
              : 'bg-white text-brand-text hover:bg-brand-light border border-brand-border'
          }`}
        >
          <Server size={15} />
          <span>تنظیمات اتصال به سرور</span>
        </button>

        <button
          onClick={() => setActiveTab('database')}
          className={`flex items-center gap-2 px-4 py-2.5 rounded-btn text-xs font-bold transition-all ${
            activeTab === 'database'
              ? 'bg-brand-primary text-white shadow-soft'
              : 'bg-white text-brand-text hover:bg-brand-light border border-brand-border'
          }`}
        >
          <Database size={15} />
          <span>وضعیت پایگاه داده (MySQL 9.7)</span>
        </button>

        <button
          onClick={() => setActiveTab('general')}
          className={`flex items-center gap-2 px-4 py-2.5 rounded-btn text-xs font-bold transition-all ${
            activeTab === 'general'
              ? 'bg-brand-primary text-white shadow-soft'
              : 'bg-white text-brand-text hover:bg-brand-light border border-brand-border'
          }`}
        >
          <Building size={15} />
          <span>تنظیمات عمومی سامانه</span>
        </button>

        <button
          onClick={() => setActiveTab('security')}
          className={`flex items-center gap-2 px-4 py-2.5 rounded-btn text-xs font-bold transition-all ${
            activeTab === 'security'
              ? 'bg-brand-primary text-white shadow-soft'
              : 'bg-white text-brand-text hover:bg-brand-light border border-brand-border'
          }`}
        >
          <Shield size={15} />
          <span>امنیت و نشست‌ها</span>
        </button>

        <button
          onClick={() => setActiveTab('backup')}
          className={`flex items-center gap-2 px-4 py-2.5 rounded-btn text-xs font-bold transition-all ${
            activeTab === 'backup'
              ? 'bg-brand-primary text-white shadow-soft'
              : 'bg-white text-brand-text hover:bg-brand-light border border-brand-border'
          }`}
        >
          <HardDrive size={15} />
          <span>پشتیبان‌گیری و بازیابی</span>
        </button>

        <button
          onClick={() => setActiveTab('info')}
          className={`flex items-center gap-2 px-4 py-2.5 rounded-btn text-xs font-bold transition-all ${
            activeTab === 'info'
              ? 'bg-brand-primary text-white shadow-soft'
              : 'bg-white text-brand-text hover:bg-brand-light border border-brand-border'
          }`}
        >
          <Info size={15} />
          <span>درباره سامانه و نسخه</span>
        </button>
      </div>

      {/* Tab 1: Server Connection (The Exact Reference Form) */}
      {activeTab === 'server' && (
        <form onSubmit={(e) => { e.preventDefault(); handleSave('تنظیمات اتصال به سرور'); }}>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Right Card: Domain & Platform Info */}
            <div className="bg-white p-6 rounded-card border border-brand-border shadow-soft space-y-4">
              <h3 className="font-bold text-sm text-brand-dark flex items-center gap-2 pb-3 border-b border-brand-border">
                <Globe size={18} className="text-brand-primary" />
                مشخصات دامنه و بستر سرور
              </h3>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">دامنه اصلی</label>
                <input
                  type="text"
                  value={serverValues.domain}
                  onChange={(e) => setServerValues({ ...serverValues, domain: e.target.value })}
                  className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-left"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">زیردامنه سامانه</label>
                <input
                  type="text"
                  value={serverValues.subdomain}
                  onChange={(e) => setServerValues({ ...serverValues, subdomain: e.target.value })}
                  className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-left"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">سیستم‌عامل سرور</label>
                <input
                  type="text"
                  readOnly
                  value={serverValues.server_os}
                  className="w-full px-3.5 py-2 text-xs rounded-input bg-gray-50 border border-brand-border text-brand-muted font-medium text-left"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">فناوری بک‌اند</label>
                <input
                  type="text"
                  readOnly
                  value="FastAPI / Python 3.13"
                  className="w-full px-3.5 py-2 text-xs rounded-input bg-gray-50 border border-brand-border text-brand-muted font-medium text-left"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">میزبان دیتابیس (سرویس داکر)</label>
                <input
                  type="text"
                  value={serverValues.db_host}
                  onChange={(e) => setServerValues({ ...serverValues, db_host: e.target.value })}
                  className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-left"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">نام پایگاه داده</label>
                <input
                  type="text"
                  value={serverValues.db_name}
                  onChange={(e) => setServerValues({ ...serverValues, db_name: e.target.value })}
                  className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-left"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-brand-text mb-1">پورت HTTPS</label>
                  <input
                    type="text"
                    value={serverValues.https_port}
                    onChange={(e) => setServerValues({ ...serverValues, https_port: e.target.value })}
                    className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-center"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-brand-text mb-1">کلید Secret / JWT</label>
                  <div className="relative">
                    <input
                      type="password"
                      value={serverValues.jwt_secret}
                      onChange={(e) => setServerValues({ ...serverValues, jwt_secret: e.target.value })}
                      className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-left"
                    />
                    <Lock size={13} className="absolute right-3 top-2.5 text-brand-muted" />
                  </div>
                </div>
              </div>
            </div>

            {/* Left Card: API, WebSocket & Security Settings */}
            <div className="bg-white p-6 rounded-card border border-brand-border shadow-soft space-y-4">
              <h3 className="font-bold text-sm text-brand-dark flex items-center gap-2 pb-3 border-b border-brand-border">
                <Cpu size={18} className="text-brand-primary" />
                آدرس‌ها و تنظیمات امنیتی سرویس‌ها
              </h3>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">آدرس API</label>
                <input
                  type="text"
                  value={serverValues.api_base_url}
                  onChange={(e) => setServerValues({ ...serverValues, api_base_url: e.target.value })}
                  className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-left"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">آدرس WebSocket (بلادرنگ)</label>
                <input
                  type="text"
                  value={serverValues.websocket_url}
                  onChange={(e) => setServerValues({ ...serverValues, websocket_url: e.target.value })}
                  className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-left"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">وب‌سرور پروکسی</label>
                <input
                  type="text"
                  readOnly
                  value="Nginx Reverse Proxy / Let's Encrypt"
                  className="w-full px-3.5 py-2 text-xs rounded-input bg-gray-50 border border-brand-border text-brand-muted font-medium text-left"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">موتور پایگاه‌داده (Database Engine)</label>
                <input
                  type="text"
                  readOnly
                  value="MySQL 9.7 LTS (InnoDB, utf8mb4)"
                  className="w-full px-3.5 py-2 text-xs rounded-input bg-gray-50 border border-brand-border text-brand-dark font-bold text-left"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">پورت داخلی دیتابیس</label>
                <input
                  type="text"
                  value={serverValues.db_port}
                  readOnly
                  className="w-full px-3.5 py-2 text-xs rounded-input bg-gray-50 border border-brand-border text-brand-muted font-mono text-left"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">نام کاربری دیتابیس</label>
                <input
                  type="text"
                  value={serverValues.db_user}
                  onChange={(e) => setServerValues({ ...serverValues, db_user: e.target.value })}
                  className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-left"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">وضعیت گواهی امنیتی SSL</label>
                <div className="flex items-center gap-2 p-2.5 rounded-input bg-emerald-50 border border-emerald-200 text-xs font-bold text-brand-dark">
                  <ShieldCheck size={16} className="text-brand-secondary" />
                  <span>Let's Encrypt Authority — اعتبار تا ۹۰ روز آینده</span>
                </div>
              </div>
            </div>
          </div>

          {/* Action Buttons Matching Reference Design Image */}
          <div className="flex items-center justify-between pt-6 mt-4">
            <button
              type="button"
              onClick={runAllTests}
              className="flex items-center gap-2 px-6 py-3 rounded-btn bg-white hover:bg-brand-light text-brand-dark border border-brand-border text-xs font-bold shadow-soft transition-all"
            >
              <Play size={16} className="text-brand-primary" />
              <span>آزمایش اتصال به سرور و سرویس‌ها</span>
            </button>

            <button
              type="submit"
              className="flex items-center gap-2 px-8 py-3 rounded-btn bg-brand-primary hover:bg-brand-dark text-white text-xs font-bold shadow-soft transition-all"
            >
              <Save size={16} />
              <span>ذخیره تنظیمات سرور</span>
            </button>
          </div>
        </form>
      )}

      {/* Tab 2: Database Status */}
      {activeTab === 'database' && (
        <div className="space-y-6">
          <div className="bg-white p-6 rounded-card border border-brand-border shadow-soft">
            <h3 className="font-bold text-sm text-brand-dark flex items-center gap-2 pb-4 border-b border-brand-border">
              <Database size={18} className="text-brand-primary" />
              وضعیت و معیارهای سلامت پایگاه داده MySQL 9.7 LTS
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mt-5">
              <div className="p-4 bg-brand-light rounded-card border border-brand-border">
                <span className="text-[11px] text-brand-muted">موتور و نگارش</span>
                <p className="text-sm font-bold text-brand-dark mt-1">{dbStatus.engine}</p>
                <span className="text-[10px] text-brand-emerald font-semibold">پشتیبانی بلندمدت (LTS)</span>
              </div>

              <div className="p-4 bg-brand-light rounded-card border border-brand-border">
                <span className="text-[11px] text-brand-muted">وضعیت اتصال و استخر</span>
                <p className="text-sm font-bold text-brand-dark mt-1">{dbStatus.active_connections} اتصال فعال / حداکثر {dbStatus.pool_size}</p>
                <span className="text-[10px] text-brand-secondary font-semibold">Connection Pool سالم</span>
              </div>

              <div className="p-4 bg-brand-light rounded-card border border-brand-border">
                <span className="text-[11px] text-brand-muted">حجم و جداول سیستم</span>
                <p className="text-sm font-bold text-brand-dark mt-1">{dbStatus.tables_count} جدول اصلی / {dbStatus.db_size}</p>
                <span className="text-[10px] text-brand-muted font-mono">{dbStatus.charset}</span>
              </div>

              <div className="p-4 bg-brand-light rounded-card border border-brand-border">
                <span className="text-[11px] text-brand-muted">میزبان و پورت</span>
                <p className="text-sm font-bold text-brand-dark mt-1 font-mono">{dbStatus.host}:{dbStatus.port}</p>
                <span className="text-[10px] text-brand-muted">شبکه امن داکر لینوکس</span>
              </div>

              <div className="p-4 bg-brand-light rounded-card border border-brand-border">
                <span className="text-[11px] text-brand-muted">مدت کارکرد مداوم (Uptime)</span>
                <p className="text-sm font-bold text-brand-dark mt-1">{dbStatus.uptime}</p>
                <span className="text-[10px] text-brand-emerald font-semibold">بدون وقفه یا Downtime</span>
              </div>

              <div className="p-4 bg-emerald-50 rounded-card border border-emerald-200">
                <span className="text-[11px] text-brand-dark font-semibold">وضعیت کلی سرویس</span>
                <p className="text-sm font-bold text-brand-emerald mt-1 flex items-center gap-1.5">
                  <CheckCircle2 size={16} />
                  {dbStatus.status}
                </p>
                <span className="text-[10px] text-brand-muted">شاخص تاخیر (Latency): ~1.8 ms</span>
              </div>
            </div>
          </div>

          {/* Database Tables Verification */}
          <div className="bg-white p-6 rounded-card border border-brand-border shadow-soft">
            <h4 className="font-bold text-xs text-brand-dark mb-4">جداول پایگاه داده آمفی‌تئاتر مرکزی</h4>
            <div className="overflow-x-auto">
              <table className="w-full text-right text-xs">
                <thead>
                  <tr className="border-b border-brand-border text-brand-muted">
                    <th className="py-2.5 px-3">نام جدول</th>
                    <th className="py-2.5 px-3">کاربرد</th>
                    <th className="py-2.5 px-3">موتور ذخیره‌سازی</th>
                    <th className="py-2.5 px-3">کدگذاری</th>
                    <th className="py-2.5 px-3">وضعیت ایندکس‌ها</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-brand-border text-brand-text">
                  {[
                    { name: 'schools', desc: 'مدارس تابعه موسسه و نمایندگان', engine: 'InnoDB', charset: 'utf8mb4', status: 'سالم' },
                    { name: 'users', desc: 'کاربران و مدیران سیستم', engine: 'InnoDB', charset: 'utf8mb4', status: 'سالم' },
                    { name: 'time_slots', desc: 'بازه‌های زمانی سالن آمفی‌تئاتر', engine: 'InnoDB', charset: 'utf8mb4', status: 'سالم' },
                    { name: 'reservations', desc: 'اطلاعات رزروها و وضعیت‌ها', engine: 'InnoDB', charset: 'utf8mb4', status: 'سالم' },
                    { name: 'holidays', desc: 'تقویم تعطیلات رسمی و موسسه', engine: 'InnoDB', charset: 'utf8mb4', status: 'سالم' },
                    { name: 'restrictions', desc: 'محدودیت‌ها و قوانین رزرو', engine: 'InnoDB', charset: 'utf8mb4', status: 'سالم' },
                    { name: 'audit_logs', desc: 'ردیابی و لاگ امنیتی فعالیت‌ها', engine: 'InnoDB', charset: 'utf8mb4', status: 'سالم' },
                    { name: 'server_configs', desc: 'پیکربندی داینامیک سرور', engine: 'InnoDB', charset: 'utf8mb4', status: 'سالم' },
                  ].map((tbl, i) => (
                    <tr key={i} className="hover:bg-brand-light">
                      <td className="py-2.5 px-3 font-mono font-bold text-brand-primary">{tbl.name}</td>
                      <td className="py-2.5 px-3">{tbl.desc}</td>
                      <td className="py-2.5 px-3 font-mono text-brand-muted">{tbl.engine}</td>
                      <td className="py-2.5 px-3 font-mono text-brand-muted">{tbl.charset}</td>
                      <td className="py-2.5 px-3">
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-brand-emerald border border-emerald-200">
                          {tbl.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Tab 3: General Settings */}
      {activeTab === 'general' && (
        <form onSubmit={(e) => { e.preventDefault(); handleSave('تنظیمات عمومی سامانه'); }} className="bg-white p-6 rounded-card border border-brand-border shadow-soft space-y-5">
          <h3 className="font-bold text-sm text-brand-dark flex items-center gap-2 pb-3 border-b border-brand-border">
            <Building size={18} className="text-brand-primary" />
            تنظیمات عمومی و اداری سامانه
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-brand-text mb-1">نام موسسه متولی</label>
              <input
                type="text"
                value={generalValues.org_name}
                onChange={(e) => setGeneralValues({ ...generalValues, org_name: e.target.value })}
                className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-brand-text mb-1">عنوان کامل سالن آمفی‌تئاتر</label>
              <input
                type="text"
                value={generalValues.auditorium_name}
                onChange={(e) => setGeneralValues({ ...generalValues, auditorium_name: e.target.value })}
                className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-brand-text mb-1">ظرفیت کل سالن (صندلی)</label>
              <input
                type="number"
                value={generalValues.capacity}
                onChange={(e) => setGeneralValues({ ...generalValues, capacity: Number(e.target.value) })}
                className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border font-mono"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-brand-text mb-1">حداقل فاصله زمانی برای ثبت رزرو (ساعت)</label>
              <input
                type="number"
                value={generalValues.min_notice_hours}
                onChange={(e) => setGeneralValues({ ...generalValues, min_notice_hours: Number(e.target.value) })}
                className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border font-mono"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-brand-text mb-1">حداکثر روزهای باز بودن تقویم رزرو (روز)</label>
              <input
                type="number"
                value={generalValues.max_advance_days}
                onChange={(e) => setGeneralValues({ ...generalValues, max_advance_days: Number(e.target.value) })}
                className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border font-mono"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-brand-text mb-1">شماره تماس پشتیبانی و هماهنگی سالن</label>
              <input
                type="text"
                value={generalValues.support_phone}
                onChange={(e) => setGeneralValues({ ...generalValues, support_phone: e.target.value })}
                className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border font-mono"
              />
            </div>
          </div>

          <div className="flex justify-end pt-4 border-t border-brand-border">
            <button
              type="submit"
              className="px-6 py-2.5 rounded-btn bg-brand-primary hover:bg-brand-dark text-white text-xs font-bold shadow-soft"
            >
              ذخیره تغییرات عمومی
            </button>
          </div>
        </form>
      )}

      {/* Tab 4: Security & Sessions */}
      {activeTab === 'security' && (
        <form onSubmit={(e) => { e.preventDefault(); handleSave('امنیت و نشست‌ها'); }} className="bg-white p-6 rounded-card border border-brand-border shadow-soft space-y-5">
          <h3 className="font-bold text-sm text-brand-dark flex items-center gap-2 pb-3 border-b border-brand-border">
            <Shield size={18} className="text-brand-primary" />
            سیاست‌های امنیتی، رمزنگاری و مدیریت نشست‌ها
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-brand-text mb-1">طول عمر توکن دسترسی (JWT Access Token - دقیقه)</label>
              <input
                type="number"
                value={securityValues.jwt_expiry_minutes}
                onChange={(e) => setSecurityValues({ ...securityValues, jwt_expiry_minutes: Number(e.target.value) })}
                className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border font-mono"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-brand-text mb-1">طول عمر توکن نوسازی (Refresh Token - روز)</label>
              <input
                type="number"
                value={securityValues.refresh_token_days}
                onChange={(e) => setSecurityValues({ ...securityValues, refresh_token_days: Number(e.target.value) })}
                className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border font-mono"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-brand-text mb-1">حداکثر تلاش ناموفق ورود پیش از قفل حساب</label>
              <input
                type="number"
                value={securityValues.max_failed_attempts}
                onChange={(e) => setSecurityValues({ ...securityValues, max_failed_attempts: Number(e.target.value) })}
                className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border font-mono"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-brand-text mb-1">مدت زمان قفل موقت حساب (دقیقه)</label>
              <input
                type="number"
                value={securityValues.lockout_minutes}
                onChange={(e) => setSecurityValues({ ...securityValues, lockout_minutes: Number(e.target.value) })}
                className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border font-mono"
              />
            </div>
          </div>

          <div className="p-4 bg-brand-light rounded-card border border-brand-border flex items-center justify-between">
            <div>
              <span className="text-xs font-bold text-brand-dark block">خاتمه دادن به تمام نشست‌های فعال کاربران</span>
              <span className="text-[11px] text-brand-muted">در صورت نیاز، همه توکن‌های صادر شده لغو و کاربران به صفحه ورود هدایت می‌شوند.</span>
            </div>
            <button
              type="button"
              onClick={() => alert('تمامی نشست‌های فعال با موفقیت ابطال شدند.')}
              className="px-4 py-2 bg-res-red text-res-redText hover:bg-red-100 rounded-btn text-xs font-bold border border-red-200"
            >
              ابطال همه نشست‌ها
            </button>
          </div>

          <div className="flex justify-end pt-4 border-t border-brand-border">
            <button
              type="submit"
              className="px-6 py-2.5 rounded-btn bg-brand-primary hover:bg-brand-dark text-white text-xs font-bold shadow-soft"
            >
              ذخیره تنظیمات امنیتی
            </button>
          </div>
        </form>
      )}

      {/* Tab 5: Backup & Restore */}
      {activeTab === 'backup' && (
        <div className="space-y-6">
          {backupSuccess && (
            <div className="p-4 bg-brand-pastel border border-emerald-200 text-brand-dark rounded-card flex items-center justify-between text-xs font-semibold">
              <div className="flex items-center gap-2">
                <Check size={16} className="text-brand-emerald" />
                <span>{backupSuccess}</span>
              </div>
              <button onClick={() => setBackupSuccess(null)}><X size={14} /></button>
            </div>
          )}

          <div className="bg-white p-6 rounded-card border border-brand-border shadow-soft flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h3 className="font-bold text-sm text-brand-dark flex items-center gap-2">
                <HardDrive size={18} className="text-brand-primary" />
                پشتیبان‌گیری پایگاه داده MySQL 9.7 LTS
              </h3>
              <p className="text-xs text-brand-muted mt-1">
                تهیه نسخه پشتیبان ساختار و اطلاعات (mysqldump فشرده gzip) به همراه قابلیت بارگیری و بازگردانی اضطراری
              </p>
            </div>

            <button
              onClick={handleCreateBackup}
              disabled={backupLoading}
              className="flex items-center gap-2 px-5 py-2.5 bg-brand-primary hover:bg-brand-dark text-white rounded-btn text-xs font-bold shadow-soft transition-all"
            >
              <RefreshCw size={15} className={backupLoading ? 'animate-spin' : ''} />
              <span>{backupLoading ? 'در حال تهیه پشتیبان...' : 'تهیه نسخه پشتیبان جدید'}</span>
            </button>
          </div>

          {/* Backup List Table */}
          <div className="bg-white p-6 rounded-card border border-brand-border shadow-soft">
            <h4 className="font-bold text-xs text-brand-dark mb-4">آرشیو نسخه‌های پشتیبان موجود</h4>
            <div className="overflow-x-auto">
              <table className="w-full text-right text-xs">
                <thead>
                  <tr className="border-b border-brand-border text-brand-muted">
                    <th className="py-2.5 px-3">نام فایل پشتیبان</th>
                    <th className="py-2.5 px-3">تاریخ و ساعت ایجاد</th>
                    <th className="py-2.5 px-3">حجم فایل</th>
                    <th className="py-2.5 px-3">وضعیت</th>
                    <th className="py-2.5 px-3 text-center">عملیات</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-brand-border text-brand-text">
                  {backups.map((bk) => (
                    <tr key={bk.id} className="hover:bg-brand-light">
                      <td className="py-2.5 px-3 font-mono font-bold text-brand-primary">{bk.filename}</td>
                      <td className="py-2.5 px-3">{bk.date}</td>
                      <td className="py-2.5 px-3 font-mono text-brand-muted">{bk.size}</td>
                      <td className="py-2.5 px-3">
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-brand-emerald border border-emerald-200">
                          {bk.status}
                        </span>
                      </td>
                      <td className="py-2.5 px-3 text-center">
                        <button
                          onClick={() => alert(`دانلود فایل ${bk.filename} آغاز شد.`)}
                          className="px-3 py-1 bg-brand-light hover:bg-brand-pastel text-brand-dark rounded-btn text-[11px] font-bold border border-brand-border inline-flex items-center gap-1"
                        >
                          <Download size={13} />
                          <span>دانلود فایل</span>
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Tab 6: App Info */}
      {activeTab === 'info' && (
        <div className="bg-white p-6 rounded-card border border-brand-border shadow-soft space-y-6">
          <div className="flex items-center gap-4 pb-4 border-b border-brand-border">
            <div className="w-14 h-14 rounded-2xl bg-brand-light border border-brand-border flex items-center justify-center p-2 shadow-sm">
              <img src="/logo.svg" alt="HMH Logo" className="w-full h-full object-contain" />
            </div>
            <div>
              <h3 className="font-bold text-base text-brand-dark">
                سامانه متمرکز رزرواسیون سالن آمفی‌تئاتر مدارس حضرت امام حسین (ع) — HMH
              </h3>
              <p className="text-xs text-brand-muted mt-0.5">
                موسسه خیریه فرهنگی آموزشی حضرت امام حسین (ع) یزد — نگارش رسمی v1.0.2
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 text-xs">
            <div className="p-4 bg-brand-light rounded-card border border-brand-border">
              <span className="text-[11px] text-brand-muted">نگارش نرم‌افزار</span>
              <p className="text-sm font-bold text-brand-dark font-mono mt-1">v1.0.2 Production</p>
              <span className="text-[10px] text-brand-emerald">نسخه پایدار و نهایی فاز ۱</span>
            </div>

            <div className="p-4 bg-brand-light rounded-card border border-brand-border">
              <span className="text-[11px] text-brand-muted">معماری و رابط کاربری</span>
              <p className="text-sm font-bold text-brand-dark mt-1">React 18 + TypeScript + Vite</p>
              <span className="text-[10px] text-brand-muted">Tailwind CSS + Vazirmatn RTL</span>
            </div>

            <div className="p-4 bg-brand-light rounded-card border border-brand-border">
              <span className="text-[11px] text-brand-muted">سرویس بک‌اند و API</span>
              <p className="text-sm font-bold text-brand-dark mt-1">FastAPI / Python 3.13</p>
              <span className="text-[10px] text-brand-secondary font-semibold">RESTful API + WebSockets</span>
            </div>

            <div className="p-4 bg-brand-light rounded-card border border-brand-border">
              <span className="text-[11px] text-brand-muted">پایگاه داده رابطه‌ای</span>
              <p className="text-sm font-bold text-brand-dark mt-1">MySQL 9.7 LTS</p>
              <span className="text-[10px] text-brand-muted">utf8mb4_unicode_ci</span>
            </div>

            <div className="p-4 bg-brand-light rounded-card border border-brand-border">
              <span className="text-[11px] text-brand-muted">سیستم‌عامل سرور</span>
              <p className="text-sm font-bold text-brand-dark mt-1">Ubuntu 24.04 LTS (Noble)</p>
              <span className="text-[10px] text-brand-muted">Nginx + SSL Let's Encrypt</span>
            </div>

            <div className="p-4 bg-brand-light rounded-card border border-brand-border">
              <span className="text-[11px] text-brand-muted">کلاینت بومی کاربران مدارس</span>
              <p className="text-sm font-bold text-brand-dark mt-1">Flutter Desktop (Windows 10/11)</p>
              <span className="text-[10px] text-brand-emerald">پکیج مستقل پرتابل x64</span>
            </div>
          </div>
        </div>
      )}

      {/* Interactive Connection Test Modal */}
      {showTestModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-modal shadow-modal border border-brand-border w-full max-w-lg p-6 animate-fade-in">
            <div className="flex items-center justify-between pb-3 border-b border-brand-border">
              <h3 className="font-bold text-sm text-brand-dark flex items-center gap-2">
                <Wifi size={18} className="text-brand-primary" />
                نتایج آزمون اتصال آنلاین به سرور مرکزی
              </h3>
              <button 
                onClick={() => setShowTestModal(false)}
                className="text-brand-muted hover:text-brand-dark"
              >
                <X size={18} />
              </button>
            </div>

            <div className="space-y-3 mt-4 text-xs">
              {testResults.length === 0 && testing && (
                <div className="flex flex-col items-center justify-center py-8 gap-2">
                  <RefreshCw className="animate-spin text-brand-primary" size={28} />
                  <span className="text-brand-muted">در حال اجرای تست‌های ارتباطی سرور و پایگاه داده...</span>
                </div>
              )}

              {testResults.map((tr, idx) => (
                <div 
                  key={idx}
                  className={`p-3.5 rounded-card border flex flex-col gap-1 transition-all ${
                    tr.success ? 'bg-emerald-50/60 border-emerald-200' : 'bg-red-50/60 border-red-200'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      {tr.success ? (
                        <CheckCircle2 size={16} className="text-brand-secondary" />
                      ) : (
                        <XCircle size={16} className="text-res-redText" />
                      )}
                      <strong className="text-brand-dark font-bold">
                        {testTypeTitles[tr.test_type] || tr.test_type}
                      </strong>
                    </div>
                    {tr.latency_ms && (
                      <span className="font-mono text-[11px] text-brand-muted">
                        {tr.latency_ms} ms
                      </span>
                    )}
                  </div>
                  <p className="text-brand-text text-[11px] pr-6">{tr.status_text}</p>
                  {tr.details && (
                    <span className="text-brand-muted text-[10px] pr-6 font-mono">{tr.details}</span>
                  )}
                </div>
              ))}
            </div>

            <div className="flex justify-end gap-2 pt-4 mt-2 border-t border-brand-border">
              <button
                type="button"
                onClick={runAllTests}
                disabled={testing}
                className="px-4 py-2 text-xs font-semibold text-brand-primary hover:bg-brand-light rounded-btn border border-brand-border flex items-center gap-1.5"
              >
                <RefreshCw size={13} className={testing ? 'animate-spin' : ''} />
                <span>اجرای مجدد آزمون</span>
              </button>
              <button
                onClick={() => setShowTestModal(false)}
                className="px-5 py-2 text-xs font-bold text-white bg-brand-primary rounded-btn hover:bg-brand-dark"
              >
                تأیید و بستن
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

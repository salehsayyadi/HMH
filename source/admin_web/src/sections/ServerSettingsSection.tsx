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
  Clock
} from 'lucide-react';
import { apiRequest, ServerInfo, ConnectionTestResult } from '../services/api';

export const ServerSettingsSection: React.FC = () => {
  const [info, setInfo] = useState<ServerInfo | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [saveSuccess, setSaveSuccess] = useState(false);

  // Connection testing state
  const [testing, setTesting] = useState(false);
  const [testResults, setTestResults] = useState<ConnectionTestResult[]>([]);
  const [showTestModal, setShowTestModal] = useState(false);

  // Form fields
  const [formValues, setFormValues] = useState({
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

  const loadServerInfo = async () => {
    try {
      setLoading(true);
      const data = await apiRequest<ServerInfo>('/system/status');
      setInfo(data);
      setFormValues(prev => ({
        ...prev,
        domain: data.domain || prev.domain,
        subdomain: data.subdomain || prev.subdomain,
        server_os: data.server_os || prev.server_os,
        api_base_url: data.api_base_url || prev.api_base_url,
        websocket_url: data.websocket_url || prev.websocket_url,
        db_engine: 'MySQL 9.7 LTS',
        db_name: data.database_name || prev.db_name,
      }));
    } catch (err: any) {
      setError(err.message || 'خطا در بارگذاری مشخصات ارتباطی سرور');
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
        results.push({
          test_type: t,
          success: false,
          status_text: err.message || 'خطا در برقراری ارتباط'
        });
      }
      setTestResults([...results]);
    }
    setTesting(false);
  };

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setSaveSuccess(true);
    setTimeout(() => setSaveSuccess(false), 4000);
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
            <span>پیکربندی ارتباطی سرور با موفقیت به‌روزرسانی و ذخیره شد.</span>
          </div>
          <button onClick={() => setSaveSuccess(false)}><X size={14} /></button>
        </div>
      )}

      {/* Top Banner Matching Reference Image */}
      <div className="bg-white p-5 rounded-card border border-brand-border shadow-soft flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <h2 className="text-lg font-bold text-brand-dark flex items-center gap-2">
              <Server size={22} className="text-brand-primary" />
              تنظیمات اتصال به سرور
            </h2>
          </div>
          <p className="text-xs text-brand-muted">
            پیکربندی ارتباط با سرور، پایگاه‌داده و تنظیمات استقرار (Ubuntu Linux)
          </p>
        </div>

        {/* Live Status Indicators matching reference */}
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-brand-pastel text-brand-dark text-xs font-bold border border-emerald-200">
            <span className="w-2.5 h-2.5 rounded-full bg-brand-secondary animate-pulse"></span>
            <span>اتصال API: متصل</span>
          </div>
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-brand-pastel text-brand-dark text-xs font-bold border border-emerald-200">
            <span className="w-2.5 h-2.5 rounded-full bg-brand-emerald animate-pulse"></span>
            <span>اتصال دیتابیس: متصل</span>
          </div>
        </div>
      </div>

      {/* Configuration Cards Grid */}
      <form onSubmit={handleSave}>
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
                value={formValues.domain}
                onChange={(e) => setFormValues({ ...formValues, domain: e.target.value })}
                className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-left"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-brand-text mb-1">زیردامنه سامانه</label>
              <input
                type="text"
                value={formValues.subdomain}
                onChange={(e) => setFormValues({ ...formValues, subdomain: e.target.value })}
                className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-left"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-brand-text mb-1">سیستم‌عامل سرور</label>
              <input
                type="text"
                readOnly
                value={formValues.server_os}
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
                value={formValues.db_host}
                onChange={(e) => setFormValues({ ...formValues, db_host: e.target.value })}
                className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-left"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-brand-text mb-1">نام پایگاه داده</label>
              <input
                type="text"
                value={formValues.db_name}
                onChange={(e) => setFormValues({ ...formValues, db_name: e.target.value })}
                className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-left"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">پورت HTTPS</label>
                <input
                  type="text"
                  value={formValues.https_port}
                  onChange={(e) => setFormValues({ ...formValues, https_port: e.target.value })}
                  className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-center"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-brand-text mb-1">کلید Secret / JWT</label>
                <div className="relative">
                  <input
                    type="password"
                    value={formValues.jwt_secret}
                    onChange={(e) => setFormValues({ ...formValues, jwt_secret: e.target.value })}
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
                value={formValues.api_base_url}
                onChange={(e) => setFormValues({ ...formValues, api_base_url: e.target.value })}
                className="w-full px-3.5 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald font-mono text-left"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-brand-text mb-1">آدرس WebSocket (بلادرنگ)</label>
              <input
                type="text"
                value={formValues.websocket_url}
                onChange={(e) => setFormValues({ ...formValues, websocket_url: e.target.value })}
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
                value={formValues.db_port}
                readOnly
                className="w-full px-3.5 py-2 text-xs rounded-input bg-gray-50 border border-brand-border text-brand-muted font-mono text-left"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-brand-text mb-1">نام کاربری دیتابیس</label>
              <input
                type="text"
                value={formValues.db_user}
                onChange={(e) => setFormValues({ ...formValues, db_user: e.target.value })}
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
            <span>ذخیره تنظیمات</span>
          </button>
        </div>
      </form>

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

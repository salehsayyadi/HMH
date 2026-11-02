import React, { useState, useEffect } from 'react';
import { History, Search, Filter, ShieldCheck, Clock, User, Eye, X, RefreshCw } from 'lucide-react';
import { apiRequest } from '../services/api';

interface AuditLog {
  id: number;
  actor_id?: number;
  actor_name?: string;
  action: string;
  target_type?: string;
  target_id?: string;
  before_state?: string;
  after_state?: string;
  ip_address?: string;
  status: string;
  timestamp: string;
  jalali_timestamp: string;
}

const fallbackAuditLogs: AuditLog[] = [
  {
    id: 501,
    actor_id: 1,
    actor_name: 'مدیر کل سامانه',
    action: 'AUTH_LOGIN',
    target_type: 'AUTH',
    ip_address: '192.168.1.10',
    status: 'SUCCESS',
    timestamp: new Date().toISOString(),
    jalali_timestamp: '۱۱ آبان ۱۴۰۵ — ۱۱:۴۵'
  },
  {
    id: 502,
    actor_id: 2,
    actor_name: 'محمدمحسن کارستان (دبیرستان پسرانه د.دوم)',
    action: 'RESERVATION_CREATE',
    target_type: 'RESERVATION',
    target_id: '101',
    after_state: 'رزرو بازه ۱۵:۰۰ تا ۱۷:۰۰ تاریخ ۱۴۰۵/۰۸/۱۱',
    ip_address: '192.168.1.105',
    status: 'SUCCESS',
    timestamp: new Date(Date.now() - 3600000).toISOString(),
    jalali_timestamp: '۱۱ آبان ۱۴۰۵ — ۱۰:۳۰'
  },
  {
    id: 503,
    actor_id: 3,
    actor_name: 'فاطمه کریمی (دبستان دخترانه)',
    action: 'RESERVATION_CREATE',
    target_type: 'RESERVATION',
    target_id: '102',
    after_state: 'رزرو بازه ۰۸:۰۰ تا ۱۰:۰۰ تاریخ ۱۴۰۵/۰۸/۱۲',
    ip_address: '192.168.1.112',
    status: 'SUCCESS',
    timestamp: new Date(Date.now() - 7200000).toISOString(),
    jalali_timestamp: '۱۱ آبان ۱۴۰۵ — ۰۹:۱۵'
  },
  {
    id: 504,
    actor_id: 5,
    actor_name: 'مریم حسینی (دبیرستان دخترانه د.اول)',
    action: 'RESERVATION_CANCEL',
    target_type: 'RESERVATION',
    target_id: '103',
    before_state: 'تأیید شده',
    after_state: 'لغو به علت تغییر زمان جلسه انجمن',
    ip_address: '192.168.1.118',
    status: 'SUCCESS',
    timestamp: new Date(Date.now() - 86400000).toISOString(),
    jalali_timestamp: '۱۰ آبان ۱۴۰۵ — ۱۶:۰۰'
  },
  {
    id: 505,
    actor_id: 1,
    actor_name: 'مدیر کل سامانه',
    action: 'CONFIG_UPDATE',
    target_type: 'SYSTEM_SETTINGS',
    after_state: 'به‌روزرسانی تنظیمات اتصال سرور و پایگاه داده MySQL 9.7',
    ip_address: '192.168.1.10',
    status: 'SUCCESS',
    timestamp: new Date(Date.now() - 172800000).toISOString(),
    jalali_timestamp: '۰۹ آبان ۱۴۰۵ — ۱۴:۲۰'
  }
];

export const AuditLogsSection: React.FC = () => {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedLog, setSelectedLog] = useState<AuditLog | null>(null);
  const [filterAction, setFilterAction] = useState('');
  const [isOfflinePreview, setIsOfflinePreview] = useState(false);

  const loadLogs = async () => {
    try {
      setLoading(true);
      const url = filterAction ? `/audit-logs?action=${filterAction}` : '/audit-logs';
      const data = await apiRequest<AuditLog[]>(url);
      setLogs(data);
      setIsOfflinePreview(false);
    } catch {
      setLogs(fallbackAuditLogs);
      setIsOfflinePreview(true);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadLogs();
  }, [filterAction]);

  const actionLabels: Record<string, string> = {
    AUTH_LOGIN: 'ورود به سامانه',
    PASSWORD_CHANGE: 'تغییر کلمه عبور',
    USER_CREATE: 'تعریف کاربر جدید',
    USER_UPDATE: 'ویرایش مشخصات کاربر',
    SCHOOL_CREATE: 'ثبت مدرسه جدید',
    SCHOOL_UPDATE: 'ویرایش مدرسه',
    RESERVATION_CREATE: 'ثبت رزرو جدید',
    RESERVATION_CANCEL: 'لغو رزرو',
    TIMESLOT_CREATE: 'تعریف سانس جدید',
    TIMESLOT_UPDATE: 'ویرایش سانس',
    RESTRICTION_CREATE: 'اعمال مسدودسازی',
    RESTRICTION_REMOVE: 'حذف مسدودسازی'
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-5 rounded-card border border-brand-border shadow-soft">
        <div>
          <h2 className="text-lg font-bold text-brand-dark flex items-center gap-2">
            <History size={20} className="text-brand-primary" />
            تاریخچه فعالیت‌ها و ردپای امنیتی (Audit Log)
          </h2>
          <p className="text-xs text-brand-muted mt-1">
            ثبت غیرقابل تغییر تمامی رویدادها، ورودها، ایجاد یا لغو رزروها و تغییرات سیستمی
          </p>
        </div>
        <button
          onClick={loadLogs}
          className="flex items-center justify-center gap-2 px-3.5 py-2 bg-brand-light hover:bg-brand-pastel text-brand-primary border border-brand-border rounded-btn text-xs font-bold transition-all shadow-sm"
        >
          <RefreshCw size={14} />
          <span>به‌روزرسانی وقایع</span>
        </button>
      </div>

      {/* Filter Bar */}
      <div className="flex items-center gap-3 bg-white p-4 rounded-card border border-brand-border shadow-soft">
        <span className="text-xs font-bold text-brand-dark flex items-center gap-1.5">
          <Filter size={15} /> فیلتر بر اساس عملیات:
        </span>
        <select
          value={filterAction}
          onChange={(e) => setFilterAction(e.target.value)}
          className="px-3 py-2 text-xs rounded-input bg-brand-light border border-brand-border focus:outline-none focus:border-brand-emerald text-brand-text font-medium"
        >
          <option value="">همه رخدادها ({logs.length})</option>
          <option value="AUTH_LOGIN">ورود به سیستم (AUTH_LOGIN)</option>
          <option value="RESERVATION_CREATE">ثبت رزرو (RESERVATION_CREATE)</option>
          <option value="RESERVATION_CANCEL">لغو رزرو (RESERVATION_CANCEL)</option>
          <option value="USER_CREATE">تعریف کاربر (USER_CREATE)</option>
          <option value="RESTRICTION_CREATE">اعمال مسدودسازی (RESTRICTION_CREATE)</option>
        </select>
      </div>

      {/* Table */}
      <div className="bg-white rounded-card border border-brand-border shadow-soft overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-right text-xs">
            <thead>
              <tr className="bg-brand-light border-b border-brand-border text-brand-muted">
                <th className="py-3 px-4 font-bold">زمان و تاریخ</th>
                <th className="py-3 px-4 font-bold">اقدام‌کننده</th>
                <th className="py-3 px-4 font-bold">نوع عملیات</th>
                <th className="py-3 px-4 font-bold">موجودیت هدف</th>
                <th className="py-3 px-4 font-bold">آدرس IP</th>
                <th className="py-3 px-4 font-bold text-center">نتیجه</th>
                <th className="py-3 px-4 font-bold text-center">مشاهده جزئیات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-brand-border">
              {logs.length === 0 ? (
                <tr>
                  <td colSpan={7} className="text-center py-10 text-brand-muted">
                    رویدادی برای نمایش یافت نشد.
                  </td>
                </tr>
              ) : (
                logs.map((log) => (
                  <tr key={log.id} className="hover:bg-brand-light transition-colors">
                    <td className="py-3 px-4 font-medium text-brand-dark flex items-center gap-1.5">
                      <Clock size={13} className="text-brand-muted" />
                      <span>{log.jalali_timestamp}</span>
                    </td>
                    <td className="py-3 px-4 font-semibold text-brand-dark">
                      <div className="flex items-center gap-1.5">
                        <User size={13} className="text-brand-primary" />
                        <span>{log.actor_name || 'سیستم'}</span>
                      </div>
                    </td>
                    <td className="py-3 px-4">
                      <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-brand-dark border border-emerald-100">
                        {actionLabels[log.action] || log.action}
                      </span>
                    </td>
                    <td className="py-3 px-4 font-mono text-brand-muted text-[11px]">
                      {log.target_type ? `${log.target_type} #${log.target_id || ''}` : '—'}
                    </td>
                    <td className="py-3 px-4 font-mono text-brand-muted text-[11px]">
                      {log.ip_address || '127.0.0.1'}
                    </td>
                    <td className="py-3 px-4 text-center">
                      <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-brand-pastel text-brand-dark">
                        موفق
                      </span>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <button
                        onClick={() => setSelectedLog(log)}
                        className="p-1.5 text-brand-muted hover:text-brand-primary hover:bg-brand-light rounded-btn transition-colors"
                        title="مشاهده قبل و بعد رخداد"
                      >
                        <Eye size={15} />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Detail Modal */}
      {selectedLog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-modal shadow-modal border border-brand-border w-full max-w-lg p-6 animate-fade-in">
            <div className="flex items-center justify-between pb-3 border-b border-brand-border">
              <h3 className="font-bold text-sm text-brand-dark flex items-center gap-2">
                <ShieldCheck size={18} className="text-brand-primary" />
                مشخصات رخداد امنیتی #{selectedLog.id}
              </h3>
              <button onClick={() => setSelectedLog(null)} className="text-brand-muted hover:text-brand-dark">
                <X size={18} />
              </button>
            </div>
            
            <div className="space-y-3 mt-4 text-xs">
              <div className="grid grid-cols-2 gap-2 p-3 bg-brand-light rounded-card border border-brand-border">
                <div><span className="text-brand-muted">اقدام‌کننده:</span> <strong>{selectedLog.actor_name}</strong></div>
                <div><span className="text-brand-muted">نوع عملیات:</span> <strong>{actionLabels[selectedLog.action] || selectedLog.action}</strong></div>
                <div><span className="text-brand-muted">تاریخ شمسی:</span> <strong>{selectedLog.jalali_timestamp}</strong></div>
                <div><span className="text-brand-muted">آدرس IP:</span> <strong className="font-mono">{selectedLog.ip_address}</strong></div>
              </div>

              {selectedLog.before_state && (
                <div>
                  <span className="text-brand-muted font-bold block mb-1">وضعیت قبلی موجودیت:</span>
                  <pre className="p-2.5 bg-gray-50 border border-gray-200 rounded-btn text-[11px] font-mono text-gray-700 overflow-x-auto text-left dir-ltr">
                    {selectedLog.before_state}
                  </pre>
                </div>
              )}

              {selectedLog.after_state && (
                <div>
                  <span className="text-brand-muted font-bold block mb-1">وضعیت جدید ذخیره‌شده:</span>
                  <pre className="p-2.5 bg-emerald-50 border border-emerald-200 rounded-btn text-[11px] font-mono text-emerald-900 overflow-x-auto text-left dir-ltr">
                    {selectedLog.after_state}
                  </pre>
                </div>
              )}
            </div>

            <div className="flex justify-end pt-4 mt-2 border-t border-brand-border">
              <button
                onClick={() => setSelectedLog(null)}
                className="px-5 py-2 text-xs font-bold text-white bg-brand-primary rounded-btn hover:bg-brand-dark"
              >
                بستن
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

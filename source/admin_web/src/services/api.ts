// API Client with JWT Auth and Server Communication
export const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

export interface User {
  id: number;
  username: string;
  first_name: string;
  last_name: string;
  full_name: string;
  phone_number?: string;
  school_id?: number;
  position_id?: number;
  school?: { id: number; name: string; code?: string };
  position?: { id: number; title: string };
  role: string;
  is_active: boolean;
  must_change_password: boolean;
  created_at: string;
  last_login?: string;
}

export interface School {
  id: number;
  name: string;
  code?: string;
  description?: string;
  is_active: boolean;
  user_count?: number;
  reservation_count?: number;
  created_at: string;
}

export interface TimeSlot {
  id: number;
  slot_number: number;
  title: string;
  start_time: string;
  end_time: string;
  is_active: boolean;
}

export interface Reservation {
  id: number;
  reservation_date: string;
  jalali_date: string;
  time_slot_id: number;
  time_slot: TimeSlot;
  school_id: number;
  school_name: string;
  user_id: number;
  user_full_name: string;
  position_title?: string;
  phone_number?: string;
  description?: string;
  status: string;
  can_cancel: boolean;
  created_at: string;
}

export interface Holiday {
  id: number;
  holiday_date: string;
  jalali_date: string;
  title: string;
  is_official: boolean;
  is_manual: boolean;
  source: string;
  created_at: string;
}

export interface Restriction {
  id: number;
  restriction_type: string;
  start_date: string;
  end_date: string;
  jalali_start_date: string;
  jalali_end_date: string;
  time_slot_id?: number;
  time_slot_title?: string;
  reason: string;
  created_by_name: string;
  is_active: boolean;
  created_at: string;
}

export interface DashboardStats {
  total_users: number;
  total_schools: number;
  today_reservations: number;
  upcoming_reservations: number;
  available_slots_week: number;
  reserved_slots_week: number;
  blocked_slots_week: number;
  monthly_reservations: number;
  monthly_cancellations: number;
  reservations_by_school: { school: string; count: number }[];
  monthly_trend: { month: string; count: number }[];
  status_distribution: { status: string; count: number }[];
  recent_activity: {
    id: number;
    school: string;
    user: string;
    date: string;
    time: string;
    status: string;
    created_at: string;
  }[];
}

export interface ServerInfo {
  server_os: string;
  domain: string;
  subdomain: string;
  public_ip: string;
  api_base_url: string;
  websocket_url: string;
  https_status: string;
  ssl_status: string;
  server_port: number;
  backend_version: string;
  server_health_status: string;
  database_engine: string;
  database_status: string;
  database_version: string;
  database_name: string;
  last_db_success?: string;
}

export interface ConnectionTestResult {
  test_type: string;
  success: boolean;
  status_text: string;
  latency_ms?: number;
  details?: string;
}

// Token storage helpers
export function getAccessToken(): string | null {
  return localStorage.getItem('hmh_admin_access_token');
}

export function setTokens(access: string, refresh: string) {
  localStorage.setItem('hmh_admin_access_token', access);
  localStorage.setItem('hmh_admin_refresh_token', refresh);
}

export function clearTokens() {
  localStorage.removeItem('hmh_admin_access_token');
  localStorage.removeItem('hmh_admin_refresh_token');
}

// Base fetch wrapper
export async function apiRequest<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const token = getAccessToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string> || {}),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers,
  });

  if (response.status === 401) {
    clearTokens();
    window.dispatchEvent(new Event('auth:unauthorized'));
    throw new Error('نشست کاربری منقضی شده است. لطفاً مجدداً وارد شوید.');
  }

  if (!response.ok) {
    let errorDetail = 'خطایی در ارتباط با سرور رخ داد.';
    try {
      const errJson = await response.json();
      errorDetail = errJson.detail || errorDetail;
    } catch {
      // ignored
    }
    throw new Error(errorDetail);
  }

  return response.json();
}

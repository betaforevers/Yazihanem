// Session timeout: 1 hour (3600000 milliseconds)
const SESSION_TIMEOUT = 60 * 60 * 1000;

export interface User {
  id: string;
  email: string;
  name: string;
  role: string;
  tenant_id: string;
}

export const auth = {
  /**
   * Check if user is authenticated and session is valid
   */
  isAuthenticated(): boolean {
    if (typeof window === 'undefined') return false;

    const token = localStorage.getItem('auth_token');
    const loginTime = localStorage.getItem('login_time');

    if (!token || !loginTime) {
      return false;
    }

    // Check session timeout (1 hour)
    const elapsed = Date.now() - parseInt(loginTime);
    if (elapsed > SESSION_TIMEOUT) {
      this.logout();
      return false;
    }

    return true;
  },

  /**
   * Get current user from localStorage
   */
  getUser(): User | null {
    if (typeof window === 'undefined') return null;

    const userStr = localStorage.getItem('user');
    if (!userStr) return null;

    try {
      return JSON.parse(userStr);
    } catch {
      return null;
    }
  },

  /**
   * Get auth token
   */
  getToken(): string | null {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem('auth_token');
  },

  /**
   * Update last activity time to extend session
   */
  updateActivity(): void {
    if (typeof window === 'undefined') return;
    localStorage.setItem('login_time', Date.now().toString());
  },

  /**
   * Logout and clear all auth data
   */
  logout(): void {
    if (typeof window === 'undefined') return;
    localStorage.removeItem('auth_token');
    localStorage.removeItem('user');
    localStorage.removeItem('login_time');
  },

  /**
   * Get remaining session time in milliseconds
   */
  getRemainingTime(): number {
    if (typeof window === 'undefined') return 0;

    const loginTime = localStorage.getItem('login_time');
    if (!loginTime) return 0;

    const elapsed = Date.now() - parseInt(loginTime);
    return Math.max(0, SESSION_TIMEOUT - elapsed);
  },
};

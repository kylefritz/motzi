import type { AxiosInstance } from "axios";

// Rails' csrf_meta_tags puts the session's token in the page head.
export function csrfToken(): string | null {
  const el = document.querySelector('meta[name="csrf-token"]');
  return el ? el.getAttribute("content") : null;
}

type CsrfClient = Pick<AxiosInstance, "interceptors">;

// /admin checks the CSRF token (config/initializers/active_admin.rb), so the
// React islands mounted in admin pages (menu builder, credits form) call this
// from their entrypoint. It adds X-CSRF-Token to every same-origin request the
// client makes. The token is read per request, not once at install.
export function installCsrfHeader(client: CsrfClient): void {
  client.interceptors.request.use((config) => {
    const token = csrfToken();
    const crossOrigin = /^(https?:)?\/\//i.test(config.url ?? "");
    if (token && !crossOrigin) {
      config.headers = { ...config.headers, "X-CSRF-Token": token };
    }
    return config;
  });
}

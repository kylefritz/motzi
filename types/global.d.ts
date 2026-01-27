type Gon = {
  jsTracking?: boolean;
  stripeApiKey?: string;
  [key: string]: unknown;
};

interface Window {
  gon?: Gon;
  Stripe?: (...args: unknown[]) => unknown;
}

interface RequireContext {
  (id: string): unknown;
  keys(): string[];
}

interface NodeRequire {
  context: (path: string, deep?: boolean, filter?: RegExp) => RequireContext;
}

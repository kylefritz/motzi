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

interface WebpackRequire {
  context: (path: string, deep?: boolean, filter?: RegExp) => RequireContext;
}

declare const require: WebpackRequire;

declare var window: Window;
declare var document: Document;
declare var navigator: Navigator;
declare var location: Location;
declare var HTMLElement: typeof HTMLElement;
declare var requestAnimationFrame: (callback: FrameRequestCallback) => number;
declare var cancelAnimationFrame: (handle: number) => void;

type Gon = {
  jsTracking?: boolean;
  stripeApiKey?: string;
  [key: string]: unknown;
};

interface Window {
  gon?: Gon;
}

declare var window: Window;
declare var document: Document;
declare var navigator: Navigator;
declare var location: Location;
declare var HTMLElement: typeof HTMLElement;
declare var requestAnimationFrame: (callback: FrameRequestCallback) => number;
declare var cancelAnimationFrame: (handle: number) => void;

import { JSDOM } from "jsdom";

type DomWindow = Window & typeof globalThis;

type GlobalDom = typeof globalThis & {
  window: DomWindow;
  document: Document;
  navigator: Navigator;
  location: Location;
  HTMLElement: typeof HTMLElement;
  Node: typeof Node;
  getComputedStyle: typeof getComputedStyle;
  requestAnimationFrame: (callback: FrameRequestCallback) => number;
  cancelAnimationFrame: (handle: number) => void;
};

const dom = new JSDOM("<!doctype html><html><body></body></html>", {
  url: "http://localhost",
});
const globalDom = globalThis as unknown as GlobalDom;
globalDom.window = dom.window as unknown as DomWindow;
globalDom.document = dom.window.document;
globalDom.navigator = dom.window.navigator;
globalDom.location = dom.window.location;
globalDom.HTMLElement = dom.window.HTMLElement;
globalDom.Node = dom.window.Node;
globalDom.getComputedStyle = dom.window.getComputedStyle.bind(dom.window);
globalDom.requestAnimationFrame = (callback: FrameRequestCallback) => {
  callback(0);
  return 0;
};
globalDom.cancelAnimationFrame = () => {};
globalDom.window.requestAnimationFrame = globalDom.requestAnimationFrame;
globalDom.window.cancelAnimationFrame = globalDom.cancelAnimationFrame;

// globals.d.ts
declare global {
  interface Window {
    GetParentResourceName?: () => string;
  }
}

export {};


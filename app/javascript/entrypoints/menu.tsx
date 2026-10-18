// Run by adding <%= vite_typescript_tag "menu.tsx" %> to an erb page

import ErrorBoundary from "../packs/ErrorBoundary";
import App from "../packs/menu/App";

import React from "react";
import { createRoot } from "react-dom/client";

document.addEventListener("DOMContentLoaded", () => {
  const container = document.getElementById("react-menu");
  if (!container) return;

  createRoot(container).render(
    <ErrorBoundary>
      <App />
    </ErrorBoundary>
  );
});

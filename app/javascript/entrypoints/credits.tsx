// Run by adding <%= vite_typescript_tag "credits.tsx" %> to an erb page

import ErrorBoundary from "../packs/ErrorBoundary";
import App from "../packs/credits/App";

import React from "react";
import { createRoot } from "react-dom/client";

document.addEventListener("DOMContentLoaded", () => {
  const container = document.getElementById("react-credits");
  if (!container) return;

  createRoot(container).render(
    <ErrorBoundary>
      <App />
    </ErrorBoundary>
  );
});

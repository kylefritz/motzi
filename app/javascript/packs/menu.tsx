// Run by adding <%= javascript_include_tag 'menu' %> to an erb page

import ErrorBoundary from "./ErrorBoundary";
import App from "./menu/App";

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

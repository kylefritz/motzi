// Run by adding <%= javascript_include_tag 'credits' %> to an erb page

import ErrorBoundary from "./ErrorBoundary";
import App from "./credits/App";

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

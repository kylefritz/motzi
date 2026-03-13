// Run by adding <%= javascript_include_tag 'builder' %> to an erb page

import ErrorBoundary from "./ErrorBoundary";
import Builder from "./builder/Builder";

import React from "react";
import { createRoot } from "react-dom/client";

document.addEventListener("DOMContentLoaded", () => {
  const container = document.getElementById("react-builder");
  if (!container) return;

  createRoot(container).render(
    <ErrorBoundary>
      <Builder />
    </ErrorBoundary>
  );
});

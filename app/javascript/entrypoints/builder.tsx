// Run by adding <%= vite_typescript_tag "builder.tsx" %> to an erb page

import ErrorBoundary from "../packs/ErrorBoundary";
import Builder from "../packs/builder/Builder";

import React from "react";
import { createRoot } from "react-dom/client";
import axios from "axios";
import { installCsrfHeader } from "../lib/csrf";

// the builder writes to /admin/*.json, which checks the CSRF token
installCsrfHeader(axios);

document.addEventListener("DOMContentLoaded", () => {
  const container = document.getElementById("react-builder");
  if (!container) return;

  createRoot(container).render(
    <ErrorBoundary>
      <Builder />
    </ErrorBoundary>
  );
});

// Run by adding <%= javascript_include_tag 'builder' %> to an erb page

import ErrorBoundary from "./ErrorBoundary";
import Builder from "./builder/Builder";

import React from "react";
import ReactDOM from "react-dom";

document.addEventListener("DOMContentLoaded", () => {
  ReactDOM.render(
    <ErrorBoundary>
      <Builder />
    </ErrorBoundary>,
    document.getElementById("react-builder")
  );
});

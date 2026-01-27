// Run by adding <%= javascript_include_tag 'buy' %> to an erb page

import ErrorBoundary from "./ErrorBoundary";
import App from "./buy/App";

import React from "react";
import ReactDOM from "react-dom";

document.addEventListener("DOMContentLoaded", () => {
  ReactDOM.render(
    <ErrorBoundary>
      <App />
    </ErrorBoundary>,
    document.getElementById("react-buy")
  );
});

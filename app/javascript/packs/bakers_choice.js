// Run by adding <%= javascript_pack_tag 'bakers_choice' %> to an erb page

import ErrorBoundary from "./ErrorBoundary.js";
import App from "./bakers_choice/App";

import React from "react";
import ReactDOM from "react-dom";

document.addEventListener("DOMContentLoaded", () => {
  ReactDOM.render(
    <ErrorBoundary>
      <App />
    </ErrorBoundary>,
    document.getElementById("react-bakers-choice")
  );
});

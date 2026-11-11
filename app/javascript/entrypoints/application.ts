// Vite entrypoint (vite_typescript_tag "application"). Every file in this
// directory is an entrypoint; keep application logic elsewhere in app/javascript.

// self-hosted error reporting — install before any framework code runs
import { installGlobalErrorReporter } from "../lib/errorReporter";
installGlobalErrorReporter();

import Rails from "@rails/ujs";
import * as ActiveStorage from "@rails/activestorage";

Rails.start();
ActiveStorage.start();

// ahoy
import ahoy from "ahoy.js";
if (window.gon?.jsTracking) {
  ahoy.trackAll();
}

// Marketing pages are server-rendered; this pack only wires up the
// self-hosted error reporter and ahoy visit/click analytics.

import { installGlobalErrorReporter } from "../lib/errorReporter";
installGlobalErrorReporter();

import ahoy from "ahoy.js";
if (window.gon?.jsTracking) {
  ahoy.trackAll();
}

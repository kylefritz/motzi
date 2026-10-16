// Vite entrypoint (vite_typescript_tag "application"). Every file in this
// directory is an entrypoint; keep application logic elsewhere in app/javascript.

// self-hosted error reporting — install before any framework code runs
import { installGlobalErrorReporter } from "../lib/errorReporter";
installGlobalErrorReporter();

import Rails from "@rails/ujs";
import * as ActiveStorage from "@rails/activestorage";

Rails.start();
ActiveStorage.start();

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

// ahoy
import ahoy from "ahoy.js";
if (window.gon?.jsTracking) {
  ahoy.trackAll();
}

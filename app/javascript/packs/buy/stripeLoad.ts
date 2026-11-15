// Loading Stripe.js for the checkout, and recording when it doesn't load.
//
// js.stripe.com occasionally fails to load in a customer's browser (a weak
// connection, a content blocker). Unhandled, the card form stays blank and
// the pay button stays disabled with no explanation, so we retry once and
// then show a message with a Try again button (Payment.tsx).
import ahoy from "ahoy.js";
import type { Stripe } from "@stripe/stripe-js";
// pure: don't inject the script on import, only when a checkout asks for it
import { loadStripe } from "@stripe/stripe-js/pure";

import { reportError } from "../../lib/errorReporter";

// Wait before the automatic retry (tests shorten it).
export const stripeLoadRetry = { delayMs: 2000 };

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

// Every step of a failed load, as an ahoy event ("stripe_load") on the
// visit, so we can see how often each happens and whether the visitor
// ordered anyway:
//   script_failed     a load attempt failed (attempt 1 is retried by itself)
//   recovered         a retry loaded it
//   gave_up           both attempts failed; the customer sees the message
//   retry_clicked     the customer pressed Try again
//   element_failed    Stripe.js loaded but the card form didn't
export type StripeLoadStep =
  | "script_failed"
  | "recovered"
  | "gave_up"
  | "retry_clicked"
  | "element_failed";

export function trackStripeLoad(
  step: StripeLoadStep,
  properties: Record<string, unknown> = {}
): void {
  const props = {
    step,
    online: typeof navigator === "undefined" ? null : navigator.onLine,
    path: typeof location === "undefined" ? null : location.pathname,
    ...properties,
  };
  console.log("stripe_load", props);
  try {
    ahoy.track("stripe_load", props);
  } catch {
    /* tracking must never break checkout */
  }
}

// A failure the customer actually saw: also in /admin/error_events, under
// its own class so it's grouped and doesn't read as one of our bugs.
export function reportStripeLoadFailure(
  stage: "script" | "element",
  error: unknown,
  context: Record<string, unknown> = {}
): void {
  const e = error as { message?: string; stack?: string } | null;
  reportError({
    error_class: "StripeLoadError",
    message: `Stripe ${stage} failed to load: ${e?.message ?? String(error)}`,
    stack: e?.stack ?? "",
    url: typeof location === "undefined" ? "" : location.pathname,
    context: {
      kind: "stripe_load",
      stage,
      online: typeof navigator === "undefined" ? null : navigator.onLine,
      ...context,
    },
  });
}

// Loads Stripe.js, retrying once. loadStripe forgets a failed load, so the
// second call fetches the script again. `attempt` counts Try again presses
// (0 on the first load), for tracking.
export async function loadStripeWithRetry(
  apiKey: string,
  attempt = 0
): Promise<Stripe | null> {
  const started = Date.now();
  try {
    return await loadStripe(apiKey);
  } catch (err) {
    trackStripeLoad("script_failed", {
      attempt,
      try: 1,
      error: (err as Error)?.message,
      elapsed_ms: Date.now() - started,
    });
  }
  await sleep(stripeLoadRetry.delayMs);
  try {
    const stripe = await loadStripe(apiKey);
    trackStripeLoad("recovered", { attempt, elapsed_ms: Date.now() - started });
    return stripe;
  } catch (err) {
    trackStripeLoad("script_failed", {
      attempt,
      try: 2,
      error: (err as Error)?.message,
      elapsed_ms: Date.now() - started,
    });
    throw err;
  }
}

import { expect, test } from "bun:test";

import { cartPricing, isBelowMinimum } from "buy/pricing";
import type { MenuItem } from "../../../app/javascript/types/api";

const item = (overrides: Partial<MenuItem>): MenuItem => ({
  id: 1,
  name: "Classic",
  description: "",
  price: 8,
  credits: 1,
  image: null,
  subscriber: true,
  marketplace: true,
  payWhatYouCan: true,
  pickupDays: [],
  ...overrides,
});

const items = [
  item({ id: 1, name: "Classic", price: 8 }),
  item({ id: 2, name: "Sesame Rye", price: 8.25 }),
  item({ id: 3, name: "Pizza", price: 30, payWhatYouCan: false }),
];

test("splits fixed and pay-what-you-can lines; minimum is the fixed subtotal", () => {
  const pricing = cartPricing({
    cart: [
      { itemId: 3, quantity: 2 },
      { itemId: 1, quantity: 1 },
      { itemId: 2, quantity: 1 },
    ],
    items,
    enablePayWhatYouCan: true,
  });

  expect(pricing.fixedLines.map(({ name }) => name)).toEqual(["Pizza"]);
  expect(pricing.pwycLines.map(({ name }) => name)).toEqual([
    "Classic",
    "Sesame Rye",
  ]);
  expect(pricing.fixedSubtotal).toBe(60);
  expect(pricing.suggestedPwycSubtotal).toBe(16.25);
  expect(pricing.suggestedTotal).toBe(76.25);
  expect(pricing.minimum).toBe(60);
});

test("all pay-what-you-can has no minimum", () => {
  const pricing = cartPricing({
    cart: [{ itemId: 1, quantity: 3 }],
    items,
    enablePayWhatYouCan: true,
  });
  expect(pricing.fixedLines).toHaveLength(0);
  expect(pricing.minimum).toBe(0);
  expect(pricing.suggestedTotal).toBe(24);
});

test("shop with pay what you can off makes every line fixed", () => {
  const pricing = cartPricing({
    cart: [
      { itemId: 1, quantity: 1 },
      { itemId: 3, quantity: 1 },
    ],
    items,
    enablePayWhatYouCan: false,
  });
  expect(pricing.pwycLines).toHaveLength(0);
  expect(pricing.minimum).toBe(38);
});

test("isBelowMinimum", () => {
  expect(isBelowMinimum(59.99, 60)).toBe(true);
  expect(isBelowMinimum(60, 60)).toBe(false);
  expect(isBelowMinimum(null, 60)).toBe(true);
  expect(isBelowMinimum(NaN, 60)).toBe(true);
  expect(isBelowMinimum(0, 0)).toBe(false);
  expect(isBelowMinimum(null, 0)).toBe(false);
});

test("isBelowMinimum compares in cents, so float totals at the minimum pass", () => {
  // 3 × $0.60 and $4.35 + $2.10 land a hair under their rounded minimums
  expect(3 * 0.6).toBeLessThan(1.8);
  expect(isBelowMinimum(3 * 0.6, 1.8)).toBe(false);
  expect(4.35 + 2.1).toBeLessThan(6.45);
  expect(isBelowMinimum(4.35 + 2.1, 6.45)).toBe(false);

  // one cent either side of the boundary
  expect(isBelowMinimum(6.44, 6.45)).toBe(true);
  expect(isBelowMinimum(6.45, 6.45)).toBe(false);
  expect(isBelowMinimum(6.46, 6.45)).toBe(false);
  expect(isBelowMinimum(1.79, 1.8)).toBe(true);
});

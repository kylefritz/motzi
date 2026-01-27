import { expect, test } from "bun:test";
import { renderHook, act } from "@testing-library/react-hooks";

import { useCart } from "menu/Cart";

const thur = 1;
const sat = 2;

const makePickupDays = (satRemaining) => [
  { id: thur, remaining: 10 },
  { id: sat, remaining: satRemaining },
];

const items = [
  { id: 1, price: 1, credits: 100, pickupDays: makePickupDays(0) },
  { id: 2, price: 10, credits: 10, pickupDays: makePickupDays(null) },
  { id: 3, price: 100, credits: 1, pickupDays: makePickupDays(NaN) },
];

test("Order snapshot", () => {
  const { result } = renderHook(() => useCart({ items }));
  act(() => {
    result.current.addToCart({ id: 1, quantity: 1, pickupDayId: thur });
  });
  let midpoint;
  act(() => {
    midpoint = result.current.addToCart({
      id: 2,
      quantity: 3,
      pickupDayId: thur,
    });
  });
  expect(result.current.total.price).toStrictEqual(midpoint);

  act(() => {
    result.current.addToCart({ id: 3, quantity: 1, pickupDayId: sat });
  });
  let done;
  act(() => {
    done = result.current.addToCart({ id: 3, quantity: 2, pickupDayId: sat });
  });

  expect(result.current.total.price).toStrictEqual(done);
  expect(result.current.total).toStrictEqual({ credits: 133, price: 331 });
});

test("remove", () => {
  const { result } = renderHook(() => useCart({ items }));
  act(() => {
    result.current.addToCart({ id: 3, quantity: 2, pickupDayId: sat });
  });
  act(() => {
    result.current.addToCart({ id: 3, quantity: 1, pickupDayId: sat });
  });
  act(() => {
    result.current.addToCart({ id: 3, quantity: 3, pickupDayId: sat });
  });

  let totalAfterRm;
  act(() => {
    totalAfterRm = result.current.rmCartItem(3, 2, sat);
  });

  expect(result.current.total.price).toStrictEqual(totalAfterRm);
  expect(result.current.total).toStrictEqual({ credits: 4, price: 400 });
});

test("remaining", () => {
  const items = [
    { id: 3, subscriber: true, pickupDays: makePickupDays(NaN) },
    { id: 1, subscriber: true, pickupDays: makePickupDays(0) },
    { id: 2, subscriber: true, pickupDays: makePickupDays(null) },
    { id: -1, subscriber: true, name: "PayItForward" },
  ];

  const { result } = renderHook(() => useCart({ items }));

  act(() => {
    result.current.addToCart({ id: 1, quantity: 1, pickupDayId: thur });
  });
  expect(result.current.subscriberItems).toHaveLength(items.length - 1); // not pay it forward
  expect(result.current.subscriberItems.map(({ id }) => id)).toStrictEqual([
    3,
    1,
    2,
  ]);
  expect(result.current.subscriberItems[1].pickupDays[0].remaining).toBe(9);

  act(() => {
    result.current.addToCart({ id: 1, quantity: 1, pickupDayId: thur });
  });
  expect(result.current.subscriberItems[1].pickupDays[0].remaining).toBe(8);

  act(() => {
    result.current.addToCart({ id: 1, quantity: 3, pickupDayId: sat });
  });
  expect(result.current.subscriberItems[1].pickupDays[1].remaining).toBe(-3);

  act(() => {
    result.current.addToCart({ id: 2, quantity: 3, pickupDayId: sat });
  });
  expect(result.current.subscriberItems[2].pickupDays[1].remaining).toBe(-3);

  act(() => {
    result.current.addToCart({ id: 3, quantity: 3, pickupDayId: sat });
  });
  expect(result.current.subscriberItems.map(({ id }) => id)).toStrictEqual([
    3,
    1,
    2,
  ]);
  expect(result.current.subscriberItems[0].pickupDays[1].remaining).toBe(NaN);
});

test("no payItForward", () => {
  const items = [
    { id: 3, marketplace: true, pickupDays: makePickupDays(0) },
    { id: 1, marketplace: true, pickupDays: makePickupDays(null) },
    { id: 2, marketplace: true, pickupDays: makePickupDays(NaN) },
  ];

  const { result: no } = renderHook(() => useCart({ items }));
  expect(no.current.payItForward).toBeUndefined();

  const { result: yes } = renderHook(() =>
    useCart({ items: [...items, { id: -1, name: "PayItForward" }] })
  );
  expect(yes.current.payItForward).toBeDefined();
  expect(yes.current.payItForward.name).toMatch("PayItForward");
  expect(yes.current.marketplaceItems.map(({ id }) => id)).toStrictEqual([
    3,
    1,
    2,
  ]);
});

test("marketplaceItems vs subscriberItems", () => {
  const items = [
    { id: 1, marketplace: true, pickupDays: makePickupDays(10) },
    { id: 2, marketplace: true, pickupDays: makePickupDays(10) },
    { id: 3, marketplace: true, pickupDays: makePickupDays(10) },
    { id: 4, subscriber: true, pickupDays: makePickupDays(10) },
    { id: 5, subscriber: true, pickupDays: makePickupDays(10) },
  ];

  const {
    result: {
      current: { marketplaceItems, subscriberItems },
    },
  } = renderHook(() => useCart({ items }));

  expect(marketplaceItems.map(({ id }) => id)).toStrictEqual([1, 2, 3]);
  expect(subscriberItems.map(({ id }) => id)).toStrictEqual([4, 5]);
});

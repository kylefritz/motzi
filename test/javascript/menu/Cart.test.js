import { renderHook, act } from "@testing-library/react-hooks";

import { useCart } from "menu/Cart";

const items = [
  { id: 1, price: 1, credits: 100, remainingDay1: 10, remainingDay2: 0 },
  { id: 2, price: 10, credits: 10, remainingDay1: 10, remainingDay2: null },
  { id: 3, price: 100, credits: 1, remainingDay1: 10, remainingDay2: NaN },
];

test("Order snapshot", () => {
  const { result } = renderHook(() => useCart({ items }));
  act(() => {
    result.current.addToCart({ id: 1, quantity: 1, day: "Thursday" });
  });
  let midpoint;
  act(() => {
    midpoint = result.current.addToCart({
      id: 2,
      quantity: 3,
      day: "Thursday",
    });
  });
  expect(result.current.total.price).toStrictEqual(midpoint);

  act(() => {
    result.current.addToCart({ id: 3, quantity: 1, day: "Saturday" });
  });
  let done;
  act(() => {
    done = result.current.addToCart({ id: 3, quantity: 2, day: "Saturday" });
  });

  expect(result.current.total.price).toStrictEqual(done);
  expect(result.current.total).toStrictEqual({ credits: 133, price: 331 });
});

test("remove", () => {
  const { result } = renderHook(() => useCart({ items }));
  act(() => {
    result.current.addToCart({ id: 3, quantity: 2, day: "Saturday" });
  });
  act(() => {
    result.current.addToCart({ id: 3, quantity: 1, day: "Saturday" });
  });
  act(() => {
    result.current.addToCart({ id: 3, quantity: 3, day: "Saturday" });
  });

  let totalAfterRm;
  act(() => {
    totalAfterRm = result.current.rmCartItem(3, 2, "Saturday");
  });

  expect(result.current.total.price).toStrictEqual(totalAfterRm);
  expect(result.current.total).toStrictEqual({ credits: 4, price: 400 });
});

test("remaining", () => {
  const items = [
    { id: 3, subscriber: true, remainingDay1: 10, remainingDay2: NaN },
    { id: 1, subscriber: true, remainingDay1: 10, remainingDay2: 0 },
    { id: 2, subscriber: true, remainingDay1: 10, remainingDay2: null },
    { id: -1, subscriber: true, name: "PayItForward" },
  ];

  const { result } = renderHook(() => useCart({ items }));

  act(() => {
    result.current.addToCart({ id: 1, quantity: 1, day: "Thursday" });
  });
  expect(result.current.subscriberItems).toHaveLength(items.length - 1); // not pay it forward
  expect(result.current.subscriberItems.map(({ id }) => id)).toStrictEqual([
    3,
    1,
    2,
  ]);
  expect(result.current.subscriberItems[1].remainingDay1).toBe(9);

  act(() => {
    result.current.addToCart({ id: 1, quantity: 1, day: "Thursday" });
  });
  expect(result.current.subscriberItems[1].remainingDay1).toBe(8);

  act(() => {
    result.current.addToCart({ id: 1, quantity: 3, day: "Saturday" });
  });
  expect(result.current.subscriberItems[1].remainingDay2).toBe(-3);

  act(() => {
    result.current.addToCart({ id: 2, quantity: 3, day: "Saturday" });
  });
  expect(result.current.subscriberItems[2].remainingDay2).toBe(-3);

  act(() => {
    result.current.addToCart({ id: 3, quantity: 3, day: "Saturday" });
  });
  expect(result.current.subscriberItems.map(({ id }) => id)).toStrictEqual([
    3,
    1,
    2,
  ]);
  expect(result.current.subscriberItems[0].remainingDay2).toBe(NaN);
});

test("no payItForward", () => {
  const items = [
    { id: 3, marketplace: true, remainingDay1: 10, remainingDay2: NaN },
    { id: 1, marketplace: true, remainingDay1: 10, remainingDay2: 0 },
    { id: 2, marketplace: true, remainingDay1: 10, remainingDay2: null },
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
    { id: 1, marketplace: true },
    { id: 2, marketplace: true },
    { id: 3, marketplace: true },
    { id: 4, subscriber: true },
    { id: 5, subscriber: true },
  ];

  const {
    result: {
      current: { marketplaceItems, subscriberItems },
    },
  } = renderHook(() => useCart({ items }));

  expect(marketplaceItems.map(({ id }) => id)).toStrictEqual([1, 2, 3]);
  expect(subscriberItems.map(({ id }) => id)).toStrictEqual([4, 5]);
});

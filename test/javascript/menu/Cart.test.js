import { renderHook, act } from "@testing-library/react-hooks";

import { useCart } from "menu/Cart";

const items = [
  { id: 1, price: 1, credits: 100 },
  { id: 2, price: 10, credits: 10 },
  { id: 3, price: 100, credits: 1 },
];

test("Order snapshot", () => {
  const { result } = renderHook(() => useCart({ items }));
  act(() => {
    result.current.addToCart({ id: 1, quantity: 1, day: "Tuesday" });
  });
  let midpoint;
  act(() => {
    midpoint = result.current.addToCart({ id: 2, quantity: 3, day: "Tuesday" });
  });
  expect(result.current.total.price).toStrictEqual(midpoint);

  act(() => {
    result.current.addToCart({ id: 3, quantity: 1, day: "Thursday" });
  });
  let done;
  act(() => {
    done = result.current.addToCart({ id: 3, quantity: 2, day: "Thursday" });
  });

  expect(result.current.total.price).toStrictEqual(done);
  expect(result.current.total).toStrictEqual({ credits: 133, price: 331 });
});

test("remove", () => {
  const { result } = renderHook(() => useCart({ items }));
  act(() => {
    result.current.addToCart({ id: 3, quantity: 2, day: "Thursday" });
  });
  act(() => {
    result.current.addToCart({ id: 3, quantity: 1, day: "Thursday" });
  });
  act(() => {
    result.current.addToCart({ id: 3, quantity: 3, day: "Thursday" });
  });

  let totalAfterRm;
  act(() => {
    totalAfterRm = result.current.rmCartItem(3, 2, "Thursday");
  });

  expect(result.current.total.price).toStrictEqual(totalAfterRm);
  expect(result.current.total).toStrictEqual({ credits: 4, price: 400 });
});

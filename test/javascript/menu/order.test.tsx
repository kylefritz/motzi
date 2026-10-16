import React from "react";
import { expect, test } from "bun:test";
import { render, screen } from "@testing-library/react";

import Order from "menu/Order";
import mockMenuJson from "./mockMenuJson";

test("Order snapshot", () => {
  const { order, ...data } = mockMenuJson();
  if (!order) {
    throw new Error("mockMenuJson returned no order");
  }
  render(<Order {...data} order={order} />);

  expect(screen.getByText("We've got your order!")).toBeTruthy();
  expect(screen.getByText("Classic")).toBeTruthy();
});

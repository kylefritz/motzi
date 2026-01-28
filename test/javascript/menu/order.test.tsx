import React from "react";
import { expect, test } from "bun:test";
import { render, screen } from "@testing-library/react";

import Order from "menu/Order";
import mockMenuJson from "./mockMenuJson";

test("Order snapshot", () => {
  render(<Order {...mockMenuJson()} />);

  expect(screen.getByText("We've got your order!")).toBeTruthy();
  expect(screen.getByText("Classic")).toBeTruthy();
});

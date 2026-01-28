import React from "react";
import { expect, mock, test } from "bun:test";
import { render } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import Quantity from "menu/Quantity";

test("increments and decrements within bounds", async () => {
  const onChange = mock(() => {});
  render(<Quantity defaultQuantity={1} onChange={onChange} max={3} />);

  const buttons = document.querySelectorAll("button");
  const minusButton = buttons[0];
  const plusButton = buttons[1];

  expect(minusButton.disabled).toBe(true);
  expect(plusButton.disabled).toBe(false);

  await userEvent.click(plusButton);
  expect(onChange).toHaveBeenCalledWith(2);
  expect(minusButton.disabled).toBe(false);

  await userEvent.click(minusButton);
  expect(onChange).toHaveBeenCalledWith(1);
  expect(minusButton.disabled).toBe(true);
});

test("disables increment at max", () => {
  const onChange = mock(() => {});
  render(<Quantity defaultQuantity={2} onChange={onChange} max={2} />);

  const buttons = document.querySelectorAll("button");
  const minusButton = buttons[0];
  const plusButton = buttons[1];

  expect(minusButton.disabled).toBe(false);
  expect(plusButton.disabled).toBe(true);
});

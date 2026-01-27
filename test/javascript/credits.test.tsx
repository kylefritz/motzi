import React from "react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import App from "credits/App";

jest.mock("axios", () => ({
  post: jest.fn(() => new Promise(() => {})),
}));

jest.mock("@sentry/browser", () => ({
  captureException: jest.fn(),
}));

test("snapshot", () => {
  const { asFragment } = render(<App />);
  expect(asFragment()).toMatchSnapshot();
});

test("submits credit payload for current user", async () => {
  const axios = require("axios");
  window.history.pushState({}, "", "/admin/users/123");

  render(<App />);

  const memoInput = screen.getByText("Memo").parentElement.querySelector("input");
  const quantityInput = screen
    .getByText("Quantity")
    .parentElement.querySelector("input");
  const weeksInput = screen
    .getByText("Good for weeks")
    .parentElement.querySelector("input");

  await userEvent.type(memoInput, "promo");
  await userEvent.type(quantityInput, "5");
  await userEvent.type(weeksInput, "12");

  await userEvent.click(screen.getByRole("button", { name: "Add credit" }));

  expect(axios.post).toHaveBeenCalledWith("/admin/credit_items.json", {
    memo: "promo",
    quantity: "5",
    goodForWeeks: "12",
    userId: "123",
  });
});

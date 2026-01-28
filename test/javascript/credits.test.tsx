import React from "react";
import { expect, mock, test } from "bun:test";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

const postMock = mock(() => Promise.resolve({}));
mock.module("axios", () => ({
  default: {
    post: postMock,
  },
}));

const captureException = mock(() => {});
const configureScope = mock((cb) => cb({ setUser: () => {} }));
mock.module("@sentry/browser", () => ({
  captureException,
  configureScope,
}));

test("renders credit form", async () => {
  const { default: App } = await import("credits/App");
  render(<App />);
  expect(screen.getAllByText("Add credit")).toHaveLength(2);
});

test("submits credit payload for current user", async () => {
  const { default: App } = await import("credits/App");
  window.history.pushState({}, "", "/admin/users/123");

  render(<App />);

  const memoInput = screen
    .getByText("Memo")
    .parentElement?.querySelector("input");
  const quantityInput = screen
    .getByText("Quantity")
    .parentElement?.querySelector("input");
  const weeksInput = screen
    .getByText("Good for weeks")
    .parentElement?.querySelector("input");
  if (!memoInput || !quantityInput || !weeksInput) {
    throw new Error("Expected credit form inputs to be present.");
  }

  await userEvent.type(memoInput, "promo");
  await userEvent.type(quantityInput, "5");
  await userEvent.type(weeksInput, "12");

  await userEvent.click(screen.getByRole("button", { name: "Add credit" }));

  expect(postMock).toHaveBeenCalledWith("/admin/credit_items.json", {
    memo: "promo",
    quantity: 5,
    goodForWeeks: 12,
    userId: 123,
  });
});

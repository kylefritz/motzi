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

mock.module("../../app/javascript/lib/errorReporter", () => ({
  reportException: () => {},
  reportError: () => {},
  installGlobalErrorReporter: () => {},
}));

test("renders credit form", async () => {
  const { default: App } = await import("credits/App");
  render(<App />);
  expect(screen.getAllByText("Add credit")).toHaveLength(2);
});

test("submits credit payload for current user", async () => {
  const user = userEvent.setup();
  const { default: App } = await import("credits/App");
  window.history.pushState({}, "", "/admin/users/123");

  render(<App />);

  const memoInput = screen
    .getByText("Memo")
    .parentElement?.querySelector("input");
  const quantityInput = screen
    .getByText("Quantity")
    .parentElement?.querySelector("input");
  if (!memoInput || !quantityInput) {
    throw new Error("Expected credit form inputs to be present.");
  }

  await user.type(memoInput, "promo");
  await user.type(quantityInput, "5");

  await user.click(screen.getByRole("button", { name: "Add credit" }));

  expect(postMock).toHaveBeenCalledWith("/admin/credit_items.json", {
    memo: "promo",
    quantity: 5,
    userId: 123,
  });
});

test("the admin credit form has no expiry field", async () => {
  const { default: App } = await import("credits/App");
  render(<App />);
  expect(screen.queryByText(/good for weeks/i)).toBeNull();
});

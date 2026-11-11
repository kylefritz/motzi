import React from "react";
import { expect, mock, test } from "bun:test";
import { render } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import Tip, { applyTip } from "buy/Tip";

test("Tip interactions", async () => {
  const user = userEvent.setup();
  const onTip = mock(() => {});

  const { container } = render(<Tip onTip={onTip} tip={undefined} price={5} />);
  const tipButtons = container.querySelectorAll("button");
  expect(tipButtons).toHaveLength(4); // three amounts and "No tip"
  expect(tipButtons[0].textContent).toContain("$1");
  await user.click(tipButtons[0]);
  expect(onTip).toHaveBeenCalledTimes(1);

  const { container: container2 } = render(
    <Tip onTip={onTip} tip={undefined} price={15} />
  );
  const tipButtons2 = container2.querySelectorAll("button");
  expect(tipButtons2).toHaveLength(4); // three amounts and "No tip"
  expect(tipButtons2[0].textContent).toContain("5%");
  await user.click(tipButtons2[0]);
  expect(onTip).toHaveBeenCalledTimes(2);
});

test("applyTip", () => {
  expect(applyTip(10, "$1")).toBe(11.0);
  expect(applyTip(10, "$3")).toBe(13.0);
  expect(applyTip(10, "$10")).toBe(20.0);

  expect(applyTip(10, "10%")).toBe(11.0);
  expect(applyTip(10, "20%")).toBe(12.0);
  expect(applyTip(10, "5%")).toBe(10.5);
  expect(applyTip(13.18, "9%")).toBe(14.37);
});

test("a tip can be set back to zero with No tip", async () => {
  const user = userEvent.setup();
  const onTip = mock((_tip: string | null) => {});

  const { getByRole } = render(<Tip onTip={onTip} tip="$3" price={5} />);
  const noTip = getByRole("button", { name: "No tip" });
  expect(noTip.className).toContain("btn-outline-primary");
  expect(getByRole("button", { name: "$3" }).className).toContain(
    "btn-primary"
  );

  await user.click(noTip);
  expect(onTip).toHaveBeenCalledWith(null);
  expect(applyTip(5, null)).toBe(5);
});

test("No tip is the selected choice until a tip is added", () => {
  const { getByRole } = render(<Tip onTip={() => {}} tip={null} price={5} />);
  const noTip = getByRole("button", { name: "No tip" });
  expect(noTip.className).toContain("btn-primary");
  expect(noTip.getAttribute("aria-pressed")).toBe("true");
});

test("applyTip keeps dollar tips in whole cents", () => {
  expect(applyTip(0.14, "$1")).toBe(1.14); // 0.14 + 1 is 1.1400000000000001
});

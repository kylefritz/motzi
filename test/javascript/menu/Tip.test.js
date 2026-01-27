import React from "react";
import { render } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import Tip, { applyTip } from "buy/Tip";

test("Tip interactions", async () => {
  const onTip = jest.fn();

  const { container } = render(
    <Tip onTip={onTip} tip={undefined} price={5} />
  );
  const tipButtons = container.querySelectorAll("button");
  expect(tipButtons).toHaveLength(3);
  expect(tipButtons[0].textContent).toContain("$1");
  await userEvent.click(tipButtons[0]);
  expect(onTip).toHaveBeenCalledTimes(1);

  const { container: container2 } = render(
    <Tip onTip={onTip} tip={undefined} price={15} />
  );
  const tipButtons2 = container2.querySelectorAll("button");
  expect(tipButtons2).toHaveLength(3);
  expect(tipButtons2[0].textContent).toContain("5%");
  await userEvent.click(tipButtons2[0]);
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

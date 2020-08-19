import React from "react";
require("../configure_enzyme");
import { mount } from "enzyme";

import Tip, { applyTip } from "buy/Tip";

test("Order snapshot", () => {
  const onTip = jest.fn();
  const tip = (price) => mount(<Tip {...{ onTip, tip: undefined, price }} />);

  const tip5 = tip(5).find("TipBtn");
  expect(tip5).toHaveLength(3);
  const tip1dollar = tip5.at(0);
  expect(tip1dollar.text()).toContain("$1");
  tip1dollar.simulate("click");
  expect(onTip).toHaveBeenCalledTimes(1);

  const tip15 = tip(15).find("TipBtn");
  expect(tip15).toHaveLength(3);
  const tip5p = tip15.at(0);
  expect(tip5p.text()).toContain("5%");
  tip5p.simulate("click");
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

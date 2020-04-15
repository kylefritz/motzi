import React from "react";
import { render } from "react-dom";
import { act } from "react-dom/test-utils";
import _ from "lodash";

import Menu from "menu/Menu";
import orderData from "./order-data";

export function renderMenu() {
  const onCreateOrder = jest.fn();

  // setup a DOM element as a render target
  let container = document.createElement("div");
  document.body.appendChild(container);

  // render Menu into container
  render(<Menu {...orderData} onCreateOrder={onCreateOrder} />, container);

  return onCreateOrder;
}
export function clickItem(name) {
  act(() =>
    document
      .querySelector(`input[value="${name}"][type="radio"]`)
      .parentElement.click()
  );
}
function findAddonLabel(name) {
  return document.querySelector(`input[value="${name}"][type="checkbox"]`)
    .parentElement;
}
export function clickAddon(name) {
  act(() => findAddonLabel(name).click());
}
export function increaseAddon(name) {
  const div = findAddonLabel(name).parentElement;
  div.querySelector("button.btn-primary").click();
}
export function submitForm() {
  act(() => document.querySelector(`button[type="submit"]`).click());
}

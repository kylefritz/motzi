import React from 'react';
import { render, unmountComponentAtNode } from "react-dom";
import { act } from "react-dom/test-utils";
import * as _ from 'lodash'

import Menu from 'menu/Menu'
import orderData from './order-data'

let container = null;
beforeEach(() => {
  // setup a DOM element as a render target
  container = document.createElement("div");
  document.body.appendChild(container);
});

afterEach(() => {
  // cleanup on exiting
  unmountComponentAtNode(container);
  container.remove();
  container = null;
});

it("Menu pick skip", () => {
  const onCreateOrder = jest.fn();

  // render Menu into container
  render(<Menu {...orderData} onCreateOrder={onCreateOrder} />, container)

  // click skip radio
  act(() => document.querySelector('input[value="Skip"]').parentElement.click());

  // then click submit button
  act(() => document.querySelector('button').click());

  expect(onCreateOrder).toHaveBeenCalled();
  expect(onCreateOrder).toHaveBeenCalledTimes(1);

  // order is the 0th arg of the 0th call
  const order = onCreateOrder.mock.calls[0][0];
  expect(order).toBeTruthy()
  const { uid, items } = order;

  expect(uid).toBe('Dot9gKn9w')
  expect(items).toHaveLength(1)

  const skipItem = orderData.menu.items.filter(i => i.name == "Skip")[0]
  expect(items[0]).toBe(skipItem.id)
});

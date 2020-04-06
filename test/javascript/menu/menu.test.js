import React from 'react';
require('../configure_enzyme');
import { shallow, mount } from 'enzyme';
import { render } from "react-dom";
import { act } from "react-dom/test-utils";
import _ from 'lodash';

import Menu from 'menu/Menu'
import orderData from './order-data'

test('Menu snapshot', () => {
  const wrapper = shallow(<Menu {...orderData} />)
  expect(wrapper).toMatchSnapshot()
});

test('Menu items & addons rendered', () => {
  const wrapper = mount(<Menu {...orderData} />)
  const items = wrapper.find('input[type="radio"]')
  expect(items.length).toBe(5) // day1, day2, classic, baguette, skip

  const addOns = wrapper.find('input[type="checkbox"]')
  expect(addOns.length).toBe(2) // classic, baguette
});

test("Menu pick skip jsdom", () => {
  const onCreateOrder = jest.fn()

  // setup a DOM element as a render target
  let container = document.createElement("div")
  document.body.appendChild(container)

  // render Menu into container
  render(<Menu {...orderData} onCreateOrder={onCreateOrder} />, container)

  // click skip radio label
  act(() => document.querySelector('input[value="Skip"]').parentElement.click())

  // then click submit button
  act(() => document.querySelector('button').click())

  expect(onCreateOrder).toHaveBeenCalledTimes(1)

  // order is the 0th arg of the 0th call
  const order = onCreateOrder.mock.calls[0][0];
  expect(order).toBeTruthy()
  const { uid, items } = order

  expect(uid).toBe('Dot9gKn9w')
  expect(items).toHaveLength(1)

  const skipItem = orderData.menu.items.filter(i => i.name == "Skip")[0]
  expect(items[0]).toBe(skipItem.id)
});

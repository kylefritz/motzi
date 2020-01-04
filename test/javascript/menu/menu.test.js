import React from 'react';
require('../configure_enzyme');
import sinon from 'sinon';
import { shallow, mount } from 'enzyme';

import Menu from 'menu/Menu'
import orderData from './order-data'

test('Menu snapshot', () => {
  const wrapper = shallow(<Menu {...orderData} />);
  expect(wrapper).toMatchSnapshot();
});

test('Menu items & addons rendered', () => {
  const wrapper = mount(<Menu {...orderData} />);
  const items = wrapper.find('input[type="radio"]')
  expect(items.length).toBe(3) // classic, baget, skip

  const addOns = wrapper.find('input[type="checkbox"]')
  expect(addOns.length).toBe(2) // classic, baget
});

test.skip('Menu pick skip', () => {
  const onCreateOrder = sinon.spy();
  const wrapper = shallow(<Menu {...orderData} onCreateOrder={onCreateOrder} />);

  // we cant use enzyme to simulate this
  // because we're keeping the selection state of the radios in DOM
  // enzyme doesn't simulate enough DOM
  wrapper.find('input[value="Skip"]').simulate('change')
  wrapper.find('button').simulate('click')

  // debugger
  expect(onCreateOrder.calledOnce).toBe(true);
});

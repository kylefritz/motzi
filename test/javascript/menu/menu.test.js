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

test('Menu pick skip', () => {
  const onCreateOrder = sinon.spy();
  const wrapper = mount(<Menu {...orderData} onCreateOrder={onCreateOrder} />);

  // select skip
  wrapper.find('input[value="Skip"]').simulate('click')
  debugger
  wrapper.find('button').simulate('click')

  // debugger
  expect(onCreateOrder.calledOnce).toBe(true);
});

// test('Menu pick classic', () => {
//   const onCreateOrder = sinon.spy();
//   const wrapper = mount(<Menu {...orderData} onCreateOrder={onCreateOrder} />);

//   wrapper.find('input[value="Classic"]').simulate('click');
//   wrapper.find('button').simulate('click')

//   expect(onCreateOrder.calledOnce).toBe(true);
// });

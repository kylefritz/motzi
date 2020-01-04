import React from 'react';
require('../configure_enzyme');
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

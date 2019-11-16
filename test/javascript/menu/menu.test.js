import React from 'react';
require('../configure_enzyme');
import { shallow } from 'enzyme';

import Menu from 'menu/Menu'
import orderData from './order-data'

test('Menu snapshot', () => {
  const wrapper = shallow(<Menu {...orderData} />);
  expect(wrapper).toMatchSnapshot();
});

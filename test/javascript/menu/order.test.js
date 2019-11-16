import React from 'react';
require('../configure_enzyme');
import { shallow } from 'enzyme';

import Order from 'menu/Order'
import orderData from './order-data'

test('Order snapshot', () => {
  const wrapper = shallow(<Order {...orderData} />);
  expect(wrapper).toMatchSnapshot();
});

import React from 'react';
require('../configure_enzyme');
import { shallow } from 'enzyme';

import Preview from 'menu/Preview'
import orderData from './order-data'

test('Preview snapshot', () => {
  const wrapper = shallow(<Preview {...orderData} />);
  expect(wrapper).toMatchSnapshot();
});

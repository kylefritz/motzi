import React from 'react';
require('../configure_enzyme');
import { shallow } from 'enzyme';

import User from 'menu/User'

test('snapshot', () => {
  const user = { name: 'kyle', credits: 6, firstHalf: true }
  const wrapper = shallow(<User user={user} />);
  expect(wrapper).toMatchSnapshot();
});

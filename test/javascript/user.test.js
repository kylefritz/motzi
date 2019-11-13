import React from 'react';
import { shallow, configure } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';
configure({ adapter: new Adapter() });

import User from 'menu/User'

test('snapshot', () => {
  const user = { name: 'kyle', credits: 6, firstHalf: true }
  const wrapper = shallow(<User user={user} />);
  expect(wrapper).toMatchSnapshot();
});

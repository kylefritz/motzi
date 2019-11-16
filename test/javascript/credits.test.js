import React from 'react';
require('./configure_enzyme');
import { shallow } from 'enzyme';

import App from 'credits/App'

test('snapshot', () => {
  const wrapper = shallow(<App />);
  expect(wrapper).toMatchSnapshot();
});

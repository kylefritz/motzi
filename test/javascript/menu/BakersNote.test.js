import React from "react";
require("../configure_enzyme");
import { shallow } from "enzyme";

import BakersNote from "menu/BakersNote";

test("Menu snapshot", () => {
  const markdown = `# should be h3
  visit www.motzibakery.com.
  email motzi@gmail.com
  `;
  const wrapper = shallow(<BakersNote note={markdown} />);
  expect(wrapper).toMatchSnapshot();
});

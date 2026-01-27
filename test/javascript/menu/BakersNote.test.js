import React from "react";
import { render } from "@testing-library/react";

import BakersNote from "menu/BakersNote";

test("Menu snapshot", () => {
  const markdown = `# should be h3
  visit www.motzibakery.com.
  email motzi@gmail.com
  `;
  const { asFragment } = render(<BakersNote note={markdown} />);
  expect(asFragment()).toMatchSnapshot();
});

import React from "react";
import { render } from "@testing-library/react";

import App from "credits/App";

test("snapshot", () => {
  const { asFragment } = render(<App />);
  expect(asFragment()).toMatchSnapshot();
});

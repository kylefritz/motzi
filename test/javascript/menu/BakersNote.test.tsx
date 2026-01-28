import React from "react";
import { expect, test } from "bun:test";
import { render } from "@testing-library/react";

import BakersNote from "menu/BakersNote";

test("renders markdown", () => {
  const markdown = `# should be h3
  visit www.motzibakery.com.
  email motzi@gmail.com
  `;
  const { container } = render(<BakersNote note={markdown} />);
  const heading = container.querySelector("h3");
  expect(heading?.textContent).toBe("should be h3");
  expect(container.textContent).toContain("motzi@gmail.com");
});

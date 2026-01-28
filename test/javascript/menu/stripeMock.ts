import { mock } from "bun:test";

const elementMock = {
  mount: mock(() => {}),
  destroy: mock(() => {}),
  on: mock(() => {}),
  update: mock(() => {}),
};

const elementsMock = {
  create: mock(() => elementMock),
};

const stripeMock = {
  elements: mock(() => elementsMock),
  createToken: mock(() => Promise.resolve()),
  createSource: mock(() => Promise.resolve()),
};

export default stripeMock;

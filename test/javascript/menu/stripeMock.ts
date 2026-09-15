import { mock, type Mock } from "bun:test";

// What stripe.createToken resolves with on success.
export type StripeTokenResult = { token: { id: string }; error?: null };

const elementMock = {
  mount: mock(() => {}),
  destroy: mock(() => {}),
  on: mock(() => {}),
  update: mock(() => {}),
};

const elementsMock = {
  create: mock(() => elementMock),
};

type CreateToken = () => Promise<StripeTokenResult | void>;

const stripeMock: {
  elements: Mock<() => typeof elementsMock>;
  createToken: Mock<CreateToken>;
  createSource: Mock<() => Promise<void>>;
} = {
  elements: mock(() => elementsMock),
  createToken: mock<CreateToken>(() => Promise.resolve()),
  createSource: mock(() => Promise.resolve()),
};

export default stripeMock;

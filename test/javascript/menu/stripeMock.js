// Mocking Stripe object
const elementMock = {
  mount: jest.fn(),
  destroy: jest.fn(),
  on: jest.fn(),
  update: jest.fn(),
};

const paymentRequestMock = {
  canMakePayment: jest.fn(() => Promise.resolve()),
  on: jest.fn(),
};

const elementsMock = {
  create: jest.fn().mockReturnValue(elementMock),
};

const stripeMock = {
  elements: jest.fn().mockReturnValue(elementsMock),
  paymentRequest: jest.fn().mockReturnValue(paymentRequestMock),
  createToken: jest.fn(() => Promise.resolve()),
  createSource: jest.fn(() => Promise.resolve()),
};

export default stripeMock;

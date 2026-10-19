// Convenience types built on top of the generated schema responses.
// Source of truth: test/schemas/*.json (via bin/generate_schema_types).

import type {
  AdminItemsResponse,
  AdminMenuBuilderResponse,
  CreditItemResponse,
  ErrorEventRequest,
  MenuResponse,
  OrderErrorResponse,
} from "./api.generated";

export type {
  AdminItemsResponse,
  AdminMenuBuilderResponse,
  CreditItemResponse,
  ErrorEventRequest,
  MenuResponse,
  OrderErrorResponse,
};

export type Menu = MenuResponse["menu"];
export type MenuPickupDay = Menu["pickupDays"][number];
export type MenuItem = Menu["items"][number];
export type MenuItemPickupDay = MenuItem["pickupDays"][number];
export type CreditBundle = MenuResponse["bundles"][number];
export type MenuUser = NonNullable<MenuResponse["user"]>;
export type MenuOrder = NonNullable<MenuResponse["order"]>;
export type MenuOrderItem = MenuOrder["items"][number];
export type HolidayMenu = NonNullable<MenuResponse["holidayMenu"]>;
export type HolidayOrder = NonNullable<MenuResponse["holidayOrder"]>;

// Pay-it-forward items are added without a pickupDayId; the server assigns
// them to the menu's first pickup day.
export type CartItem = Pick<MenuOrderItem, "itemId" | "quantity"> &
  Partial<Pick<MenuOrderItem, "pickupDayId" | "day" | "pickupAt">>;

export type AdminMenu = AdminMenuBuilderResponse;
export type AdminPickupDay = AdminMenuBuilderResponse["pickupDays"][number];
export type AdminMenuItem = AdminMenuBuilderResponse["menuItems"][number];
export type AdminMenuItemPickupDay = AdminMenuItem["pickupDays"][number];
export type AdminItem = AdminItemsResponse["items"][number];

export type CreditItem = CreditItemResponse["creditItem"];

export type MenuOrderRequest = {
  uid?: string | null;
  comments?: string | null;
  cart: CartItem[];
};

// How a card payment reaches the server (#412): a ConfirmationToken from
// Stripe.js, or, after 3D Secure, the PaymentIntent the server created for
// it. Empty for a $0 order.
export type PaymentSubmission = {
  confirmationTokenId?: string;
  paymentIntentId?: string;
};

// The server's reply when a card needs 3D Secure; nothing was saved yet.
export type RequiresActionResponse = {
  requiresAction: true;
  clientSecret: string;
};

// The server's reply when the payment is still processing; the order (or
// credits) is recorded once it succeeds.
export type PendingResponse = {
  pending: true;
  message: string;
};

export type MarketplaceOrderRequest = MenuOrderRequest &
  PaymentSubmission & {
    email: string;
    firstName: string;
    lastName: string;
    phone: string;
    mailingList?: boolean;
    price: number;
  };

export type CreditPurchaseRequest = PaymentSubmission & {
  uid?: string | null;
  price: number;
  credits: number;
  breadsPerWeek: number;
};

export type AdminCreditItemRequest = {
  memo: string;
  quantity: number;
  userId: number;
};

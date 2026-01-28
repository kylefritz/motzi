// Convenience types built on top of the generated schema responses.
// Source of truth: test/schemas/*.json (via bin/generate_schema_types).

import type {
  AdminItemsResponse,
  AdminMenuBuilderResponse,
  CreditItemResponse,
  MenuResponse,
} from "./api.generated";

export type {
  AdminItemsResponse,
  AdminMenuBuilderResponse,
  CreditItemResponse,
  MenuResponse,
};

export type Menu = MenuResponse["menu"];
export type MenuPickupDay = Menu["pickupDays"][number];
export type MenuItem = Menu["items"][number];
export type MenuItemPickupDay = MenuItem["pickupDays"][number];
export type CreditBundle = MenuResponse["bundles"][number];
export type MenuUser = NonNullable<MenuResponse["user"]>;
export type MenuOrder = NonNullable<MenuResponse["order"]>;
export type MenuOrderItem = MenuOrder["items"][number];
export type OpenMenu = MenuResponse["openMenus"][number];

export type CartItem = Pick<MenuOrderItem, "itemId" | "quantity" | "pickupDayId"> &
  Partial<Pick<MenuOrderItem, "day" | "pickupAt">>;

export type AdminMenu = AdminMenuBuilderResponse;
export type AdminPickupDay = AdminMenuBuilderResponse["pickupDays"][number];
export type AdminMenuItem = AdminMenuBuilderResponse["items"][number];
export type AdminMenuItemPickupDay = AdminMenuItem["pickupDays"][number];
export type AdminItem = AdminItemsResponse["items"][number];

export type CreditItem = CreditItemResponse["creditItem"];

export type MenuOrderRequest = {
  uid?: string | null;
  menuId?: number;
  comments?: string | null;
  skip?: boolean;
  cart: CartItem[];
};

export type MarketplaceOrderRequest = MenuOrderRequest & {
  email: string;
  firstName: string;
  lastName: string;
  phone: string;
  optIn?: boolean;
  price: number;
  token: string;
};

export type CreditPurchaseRequest = {
  uid?: string | null;
  token: string;
  price: number;
  credits: number;
  breadsPerWeek: number;
};

export type AdminCreditItemRequest = {
  memo: string;
  quantity: number;
  goodForWeeks: number;
  userId: number;
};

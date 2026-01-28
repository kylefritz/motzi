import React, { useContext } from "react";

type MenuItemAddPayload = {
  itemId: number;
  subscriber: boolean;
  marketplace: boolean;
  pickupDayIds: number[];
};

type MenuItemUpdatePayload = {
  subscriber?: boolean;
  marketplace?: boolean;
  sortOrder?: number | null;
};

type PickupDayCreatePayload = {
  pickupAt: string;
  orderDeadlineAt: string;
};

type PickupDayUpdatePayload = {
  pickupAt: string;
  orderDeadlineAt: string;
};

type MenuItemPickupDayPayload = {
  menuItemId: number;
  pickupDayId: number;
};

type MenuItemPickupDayUpdatePayload = {
  id: number;
  limit: number | null | "";
};

export type BuilderApi = {
  item: {
    add: (item: MenuItemAddPayload) => Promise<unknown>;
    remove: (itemId: number) => Promise<unknown>;
    clearAll: () => Promise<unknown>;
  };
  menuItem: {
    update: (menuItemId: number, json: MenuItemUpdatePayload) => Promise<unknown>;
  };
  pickupDay: {
    add: (pickupDay: PickupDayCreatePayload) => Promise<unknown>;
    remove: (pickupDayId: number) => Promise<unknown>;
    update: (pickupDayId: number, pickupDay: PickupDayUpdatePayload) => Promise<unknown>;
  };
  menuItemPickupDay: {
    add: (payload: MenuItemPickupDayPayload) => Promise<unknown>;
    remove: (payload: MenuItemPickupDayPayload) => Promise<unknown>;
    updateLimit: (payload: MenuItemPickupDayUpdatePayload) => Promise<unknown>;
  };
};

const ApiContext = React.createContext<BuilderApi | null>(null);

export { ApiContext };

export function useApi(): BuilderApi {
  const api = useContext(ApiContext);
  if (!api) {
    throw new Error("ApiContext is missing");
  }
  return api;
}

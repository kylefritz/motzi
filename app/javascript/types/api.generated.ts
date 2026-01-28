// This file is auto-generated from test/schemas/*.json.
// Run `bin/generate_schema_types` to update.

export type AdminItemsResponse = {
  items: Array<{
    id: number;
    name: string;
    description: string;
    imagePath: null | string;
  }>;
};

export type AdminMenuBuilderResponse = {
  id: number;
  orderingDeadlineText: string;
  leadtimeHours: number | null;
  pickupDays: Array<{
    id: number;
    pickupAt: string;
    orderDeadlineAt: string;
    debug?: string;
    deadlineText?: string;
  }>;
  items: Array<{
    menuItemId: number;
    itemId: number;
    name: string;
    description: string;
    price: number;
    credits: number;
    image?: null | string;
    subscriber: boolean;
    marketplace: boolean;
    sortOrder: number | null;
    pickupDays: Array<{
      id: number;
      pickupAt: string;
      orderDeadlineAt: string;
      limit: number | null;
      debug?: string;
      deadlineText?: string;
    }>;
  }>;
};

export type CreditItemResponse = {
  creditItem: {
    id: number;
    stripeChargeId: string;
    stripeReceiptUrl: null | string;
    memo: null | string;
    quantity: number;
    userId: number;
  };
};

export type MenuResponse = {
  menu: {
    id: number;
    name: string;
    menuNote: null | string;
    subscriberNote: string;
    isCurrent: boolean;
    orderingDeadlineText: string;
    enablePayWhatYouCan: boolean;
    pickupDays: Array<{
      id: number;
      pickupAt: string;
      orderDeadlineAt: string;
      debug?: string;
    }>;
    items: Array<{
      id: number;
      name: string;
      description: string;
      price: number;
      credits: number;
      image?: null | string;
      subscriber: boolean;
      marketplace: boolean;
      pickupDays: Array<{
        id: number;
        pickupAt: string;
        orderDeadlineAt: string;
        debug?: string;
        remaining: number;
      }>;
    }>;
  };
  user: {
    id: number;
    email: string;
    name: string;
    hashid: string;
    credits: number;
    breadsPerWeek: number;
    subscriber: boolean;
  } | null;
  order: {
    items: Array<{
      itemId: number;
      quantity: number;
      day: string;
      pickupDayId: number;
      pickupAt: string;
    }>;
    id: number;
    comments: string | null;
    skip: boolean;
    stripeReceiptUrl?: string | null;
    stripeChargeAmount?: number | null;
  } | null;
  bundles: Array<{
    name: string;
    description: string | null;
    price: number;
    credits: number;
    breadsPerWeek: number;
  }>;
};


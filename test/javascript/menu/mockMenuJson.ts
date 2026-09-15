import { DateTime, Duration } from "luxon";
import { now } from "../support/clock";
import type {
  CreditBundle,
  Menu,
  MenuItem,
  MenuItemPickupDay,
  MenuOrder,
  MenuOrderItem,
  MenuPickupDay,
  MenuResponse,
  MenuUser,
} from "../../../app/javascript/types/api";

type MockMenuOptions = {
  order?: boolean | MenuOrder;
  user?: boolean | MenuUser;
  items?: boolean | MenuItem[];
  payItForward?: boolean;
  enablePayWhatYouCan?: boolean;
};

export default function ({
  order: withOrder = true,
  user: withUser = true,
  items: withItems = true,
  payItForward = true,
  enablePayWhatYouCan = true,
}: MockMenuOptions = {}): MenuResponse {
  // Relative to the fake test clock (FIXED_NOW unless a test overrides it),
  // so the menu is always open: deadline in 12h, pickup in 24h.
  const pickupAt = now().plus(Duration.fromISO("PT24H")).toISO();
  const orderDeadlineAt = now().plus(Duration.fromISO("PT12H")).toISO();
  const pickupDays: MenuPickupDay[] = [
    {
      id: 1,
      pickupAt,
      orderDeadlineAt,
    },
  ];
  // Items get their own copies: Cart mutates pickupDay.remaining in place.
  // 100 is well above the "N left!" threshold so nothing renders as scarce.
  const itemPickupDays = (): MenuItemPickupDay[] =>
    pickupDays.map((day) => ({ ...day, remaining: 100 }));
  const menu: Menu = {
    id: 921507399,
    name: "week 5",
    menuNote: "menu note copy",
    subscriberNote: "subscribers note copy",
    isCurrent: true,
    orderingDeadlineText:
      "9:00 pm Tuesday for Thursday pickup or 9:00 pm Thurs for Sat pickup",
    enablePayWhatYouCan,
    pickupDays,
    items: [],
  };
  const items: MenuItem[] = [
    {
      id: 3,
      name: "Baguette",
      description: "",
      image: "bread-baguette.jpg",
      price: 3.0,
      credits: 1,
      subscriber: true,
      marketplace: true,
      pickupDays: itemPickupDays(),
    },
    {
      id: 1,
      name: "Classic",
      description:
        "Mix of modern wheats and ancient Einkorn for the best of both worlds.",
      image: "bread2-002.webp",
      price: 4.0,
      credits: 2,
      pickupDays: itemPickupDays(),
      subscriber: true,
      marketplace: true,
    },
    {
      id: 2,
      name: "Cookies",
      description: "ony subscribers can get cookies",
      price: 4.0,
      credits: 1,
      image: null,
      pickupDays: itemPickupDays(),
      subscriber: true,
      marketplace: false,
    },
    {
      id: 4,
      name: "Marketplace only item",
      description: "too small for subscribers",
      price: 2.0,
      credits: 1,
      image: null,
      pickupDays: itemPickupDays(),
      subscriber: false,
      marketplace: true,
    },
    {
      id: 5,
      name: "Another small item",
      description: "too small for subscribers",
      price: 1.5,
      credits: 1,
      image: null,
      pickupDays: itemPickupDays(),
      subscriber: false,
      marketplace: true,
    },
  ];

  if (payItForward) {
    items.push({
      id: -1,
      name: "Pay it forward",
      description: "This purchase supports someone else in need.",
      price: 5,
      credits: 1,
      image: null,
      subscriber: false,
      marketplace: false,
      pickupDays: [],
    });
  }
  const resolvedItems =
    withItems === true ? items : withItems === false ? [] : withItems;
  menu.items = resolvedItems;

  const user: MenuUser = {
    id: 584273342,
    name: "Kyle Fritz",
    email: "kyle@example.com",
    hashid: "fake_hashid",
    credits: 9,
    breadsPerWeek: 1.0,
    receiveWeeklyMenu: true,
    receiveHaventOrderedReminder: true,
    receiveDayOfReminder: true,
  };

  const orderItems: MenuOrderItem[] = [
    {
      itemId: 3,
      quantity: 1,
      pickupDayId: pickupDays[0].id,
      pickupAt,
      day: DateTime.fromISO(pickupAt).toFormat("cccc"),
    },
    {
      itemId: 1,
      quantity: 1,
      pickupDayId: pickupDays[0].id,
      pickupAt,
      day: DateTime.fromISO(pickupAt).toFormat("cccc"),
    },
  ];

  const order: MenuOrder = {
    id: 12345,
    comments: null,
    items: orderItems,
    stripeReceiptUrl: null,
    stripeChargeAmount: null,
  };

  const bundles: CreditBundle[] = [
    {
      name: "6-Month",
      description: "Weekly",
      credits: 26,
      price: 169,
      breadsPerWeek: 1,
    },
    {
      name: "6-Month",
      description: "Bi-Weekly",
      credits: 13,
      price: 91,
      breadsPerWeek: 0.5,
    },
    {
      name: "3-Month",
      description: "Weekly",
      credits: 13,
      price: 91,
      breadsPerWeek: 1,
    },
    {
      name: "3-Month",
      description: "Bi-Weekly",
      credits: 6,
      price: 46,
      breadsPerWeek: 0.5,
    },
  ];

  // `satisfies` (rather than a widening annotation) makes this mock fail
  // `bun run typecheck` if it drifts from test/schemas/menu.json.
  const data = {
    menu,
    bundles,
    user: withUser === true ? user : withUser || null,
    order: withOrder === true ? order : withOrder || null,
    holidayMenu: null,
    holidayOrder: null,
  } satisfies MenuResponse;

  return data;
}

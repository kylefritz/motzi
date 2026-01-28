import { DateTime, Duration } from "luxon";
import type {
  CreditBundle,
  Menu,
  MenuItem,
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
  const pickupAt = DateTime.now().plus(Duration.fromISO("PT24H")).toISO();
  const orderDeadlineAt = DateTime.now()
    .plus(Duration.fromISO("PT12H"))
    .toISO();
  const pickupDays: MenuPickupDay[] = [
    {
      id: 1,
      pickupAt,
      orderDeadlineAt,
    },
  ];
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
      pickupDays,
    },
    {
      id: 1,
      name: "Classic",
      description:
        "Mix of modern wheats and ancient Einkorn for the best of both worlds.",
      image: "bread2-002.webp",
      price: 4.0,
      credits: 2,
      pickupDays,
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
      pickupDays,
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
      pickupDays,
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
      pickupDays,
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
    email: "kyle.p.fritz@gmail.com",
    hashid: "Dot9gKn9w",
    credits: 9,
    breadsPerWeek: 1.0,
    subscriber: true,
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
    skip: false,
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

  const data: MenuResponse = {
    menu,
    bundles,
    user: withUser === true ? user : withUser || null,
    order: withOrder === true ? order : withOrder || null,
    openMenus: [
      {
        id: menu.id,
        name: menu.name,
        weekId: "24w05",
        isCurrent: menu.isCurrent,
      },
    ],
  };

  return data;
}

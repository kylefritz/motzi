import { DateTime, Duration } from "luxon";

export default function ({
  order: withOrder = true,
  user: withUser = true,
  items: withItems = true,
  payItForward = true,
  enablePayWhatYouCan = true,
} = {}) {
  const pickupAt = DateTime.now().plus(Duration.fromISO("PT24H")).toISO();
  const orderDeadlineAt = DateTime.now()
    .plus(Duration.fromISO("PT12H"))
    .toISO();
  const pickupDays = [
    {
      id: 1,
      pickupAt,
      orderDeadlineAt,
    },
  ];
  const menu = {
    id: 921507399,
    name: "week 5",
    menuNote: "menu note copy",
    subscriberNote: "subscribers note copy",
    isCurrent: true,
    orderingDeadlineText:
      "9:00 pm Tuesday for Thursday pickup or 9:00 pm Thurs for Sat pickup",
    enablePayWhatYouCan,
    pickupDays,
  };
  const items = [
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
      pickupDays,
      subscriber: false,
      marketplace: true,
    },
  ];

  if (payItForward) {
    items.push({
      id: -1,
      name: "Pay it forward",
      price: 5,
      credits: 1,
    });
  }
  if (withItems) {
    menu.items = withItems === true ? items : withItems;
  }

  const user = {
    id: 584273342,
    name: "Kyle Fritz",
    email: "kyle.p.fritz@gmail.com",
    hashid: "Dot9gKn9w",
    credits: 9,
    breadsPerWeek: 1.0,
    subscriber: true,
  };

  const order = {
    skip: false,
    items: [
      {
        itemId: 3,
        quantity: 1,
        pickupDayId: pickupDays[0].id,
      },
      {
        itemId: 1,
        quantity: 1,
        pickupDayId: pickupDays[0].id,
      },
    ],
  };

  const bundles = [
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

  let data = { menu, bundles };
  if (withUser) {
    data = { ...data, user: withUser === true ? user : withUser };
  }
  if (withOrder) {
    data = { ...data, order: withOrder === true ? order : withOrder };
  }
  return data;
}

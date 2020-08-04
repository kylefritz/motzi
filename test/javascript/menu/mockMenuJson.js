import { separatePayItForward } from "menu/App";

export default function ({
  order: withOrder = true,
  user: withUser = true,
  payItForward = true,
  enablePayWhatYouCan = true,
} = {}) {
  const menu = separatePayItForward({
    id: 921507399,
    name: "week 5",
    subscriberNote: "subscribers note copy",
    menuNote: "menu note copy",
    createdAt: "2019-11-02T14:01:23.820-04:00",
    day1Deadline: "2019-11-03T23:59:59.000-04:00",
    day2Deadline: "2019-11-05T23:59:59.000-04:00",
    isCurrent: true,
    day1: "Tuesday",
    day2: "Thursday",
    day1DeadlineDay: "Sunday",
    day2DeadlineDay: "Tuesday",
    enablePayWhatYouCan,
    items: [
      {
        id: 3,
        menuItemId: 13,
        name: "Baguette",
        description: "",
        image: "bread-baguette.jpg",
        price: 3.0,
        credits: 1,
        day1: true,
        day2: true,
        subscriber: true,
        marketplace: true,
      },
      {
        id: 1,
        menuItemId: 11,
        name: "Classic",
        description:
          "Mix of modern wheats and ancient Einkorn for the best of both worlds.",
        image: "bread2-002.webp",
        price: 4.0,
        credits: 2,
        day1: true,
        day2: true,
        subscriber: true,
        marketplace: true,
      },
      {
        id: 2,
        menuItemId: 12,
        name: "Cookies",
        description: "ony subscribers can get cookies",
        price: 4.0,
        credits: 1,
        day1: true,
        day2: true,
        subscriber: true,
        marketplace: false,
      },
      {
        id: 4,
        menuItemId: 14,
        name: "Marketplace only item",
        description: "too small for subscribers",
        price: 2.0,
        credits: 1,
        day1: true,
        day2: true,
        subscriber: false,
        marketplace: true,
      },
      {
        id: 5,
        menuItemId: null,
        name: "Another small item",
        description: "too small for subscribers",
        price: 1.5,
        credits: 1,
        day1: true,
        day2: true,
        subscriber: false,
        marketplace: true,
      },
    ],
  });
  if (payItForward) {
    menu.payItForward = {
      id: -1,
      name: "Pay it forward",
      price: 5,
      credits: 1,
    };
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
        day1Pickup: true,
        day: "Tuesday",
      },
      {
        itemId: 1,
        quantity: 1,
        day1Pickup: true,
        day: "Thursday",
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

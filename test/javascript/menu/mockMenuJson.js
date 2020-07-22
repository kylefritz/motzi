import { separatePayItForwardAndSkip } from "menu/App";

export default function () {
  const menu = separatePayItForwardAndSkip({
    id: 921507399,
    name: "week 5",
    subscriberNote: "subscribers note copy",
    menuNote: "menu note copy",
    createdAt: "2019-11-02T14:01:23.820-04:00",
    day1Deadline: "2019-11-03T23:59:59.000-04:00",
    day2Deadline: "2019-11-05T23:59:59.000-04:00",
    day1: "Tuesday",
    day2: "Thursday",
    isCurrent: true,
    items: [
      {
        id: 3,
        name: "Baguette",
        description: "",
        image: "bread-baguette.jpg",
        price: 3.0,
        day1: true,
        day2: true,
        subscriber: true,
        marketplace: true,
      },
      {
        id: 1,
        name: "Classic",
        description:
          "Mix of modern wheats and ancient Einkorn for the best of both worlds.",
        image: "bread2-002.webp",
        price: 4.0,
        day1: true,
        day2: true,
        subscriber: true,
        marketplace: true,
      },
      {
        id: 2,
        name: "Cookies",
        description: "ony subscribers can get cookies",
        price: 4.0,
        day1: true,
        day2: true,
        subscriber: true,
        marketplace: false,
      },
      {
        id: 4,
        name: "Marketplace only item",
        description: "too small for subscribers",
        price: 2.0,
        day1: true,
        day2: true,
        subscriber: false,
        marketplace: true,
      },
      {
        id: 5,
        name: "Another small item",
        description: "too small for subscribers",
        price: 1.5,
        day1: true,
        day2: true,
        subscriber: false,
        marketplace: true,
      },
      {
        id: 0,
        name: "Skip",
        description: "Skip this week.",
        day1: true,
        day2: true,
        subscriber: true,
      },
    ],
  });

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

  return { menu, order, user };
}

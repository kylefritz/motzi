export default {
  menu: {
    id: 921507399,
    name: "week 5",
    bakersNote: "Orci varius",
    createdAt: "2019-11-02T14:01:23.820-04:00",
    deadline: "2019-11-03T23:59:59.000-04:00",
    isCurrent: true,
    deadlineDay: "Sunday",
    items: [
      {
        id: 3,
        name: "Baguette",
        description: "",
        image: "bread-baguette.jpg",
      },
      {
        id: 1,
        name: "Classic",
        description:
          "Mix of modern wheats and ancient Einkorn for the best of both worlds.",
        image: "bread2-002.webp",
      },
      {
        id: 0,
        name: "Skip",
        description: "Skip this week.",
      },
    ],
  },
  user: {
    id: 584273342,
    name: "Kyle Fritz",
    email: "kyle.p.fritz@gmail.com",
    hashid: "Dot9gKn9w",
    credits: 9,
    breadsPerWeek: 1.0,
  },
  order: {
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
  },
};

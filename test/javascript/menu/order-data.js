export default {
  menu: {
    id: 921507399,
    name: "week 5",
    bakersNote: "Orci varius",
    createdAt: "2019-11-02T14:01:23.820-04:00",
    isCurrent: true,
    items: [
      {
        id: 3,
        name: "Baguette",
        description: "",
        image: "bread-baguette.jpg",
        isAddOn: false,
        menuItemId: 993690591,
      },
      {
        id: 1,
        name: "Classic",
        description:
          "Mix of modern wheats and ancient Einkorn for the best of both worlds.",
        image: "bread2-002.webp",
        isAddOn: false,
        menuItemId: 993690592,
      },
      {
        id: 0,
        name: "Skip",
        description: "Skip this week.",
        isAddOn: false,
        menuItemId: 0,
      },
    ],
    addons: [
      {
        id: 1,
        name: "Classic",
        description:
          "Mix of modern wheats and ancient Einkorn for the best of both worlds.",
        image: "bread2-002.webp",
        isAddOn: true,
        menuItemId: 993690592,
      },
      {
        id: 3,
        name: "Baguette",
        description: "",
        image: "bread-baguette.jpg",
        isAddOn: true,
        menuItemId: 993690591,
      },
    ],
  },
  user: {
    id: 584273342,
    name: "Kyle Fritz",
    email: "kyle.p.fritz@gmail.com",
    hashid: "Dot9gKn9w",
    credits: 9,
    pickupDay: "Tuesday",
    breadsPerWeek: 1.0,
  },
  order: { pickupDay: "Thursday", items: [{ itemId: 3 }, { itemId: 1 }] },
};

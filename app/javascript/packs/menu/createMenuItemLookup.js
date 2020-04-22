const skip = {
  id: 0,
  name: "Skip",
  description:
    "I'd like to skip this week, please credit me for a future week (limit 3 per 6 month period).",
};
const payItForward = {
  id: -1,
  name: "Pay it forward loaf",
  description: "Wild times out there. Support some else in need.",
};

export default function createMenuItemLookup(menu) {
  const { items } = menu;
  const menuItems = _.keyBy(items, (i) => i.id);
  [skip, payItForward].forEach((item) => {
    if (!menuItems[item.id]) {
      menuItems[item.id] = item;
    }
  });
  return {
    skip: menuItems[skip.id],
    payItForward: menuItems[payItForward.id],
    menuItems,
  };
}

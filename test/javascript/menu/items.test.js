require("../configure_enzyme");
import React from "react";
import { shallow } from "enzyme";

import mockMenuJson from "./mockMenuJson";
import Items from "menu/Items";

test("render items", () => {
  const { menu } = mockMenuJson();
  const { items } = menu;

  const marketplace = shallow(<Items marketplace items={items} />);
  const numMarketPlace = items.filter(({ marketplace }) => marketplace).length;
  expect(marketplace.find("Item")).toHaveLength(numMarketPlace);

  const subscriberMenu = shallow(<Items items={items} />);
  const numSubscriber = items.filter(({ subscriber }) => subscriber).length;
  expect(subscriberMenu.find("Item")).toHaveLength(numSubscriber);

  expect(numSubscriber).not.toBe(numMarketPlace);
  expect(numSubscriber).toBeGreaterThan(0);
  expect(numMarketPlace).toBeGreaterThan(0);
});

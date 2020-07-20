require("../configure_enzyme");
import React from "react";
import { shallow } from "enzyme";

import mockMenuJson from "./mockMenuJson";
import Items from "menu/Items";

test("marketplace render menu", () => {
  const { menu } = mockMenuJson();
  const { items } = menu;

  const marketplace = shallow(<Items marketplace items={items} />);
  expect(marketplace.find("Item").length).toBe(4);

  const subscriberMenu = shallow(<Items items={items} />);
  expect(subscriberMenu.find("Item").length).toBe(3);
});

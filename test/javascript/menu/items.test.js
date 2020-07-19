require("../configure_enzyme");
import React from "react";
import { shallow } from "enzyme";

import orderData from "./order-data";
import { munge } from "menu/App";
import Items from "menu/Items";

test("marketplace render menu", () => {
  const { items } = munge(orderData.menu);

  const marketplace = shallow(<Items items={items} marketplaceView={true} />);
  expect(marketplace.find("Item").length).toBe(4);

  const subscriberMenu = shallow(<Items items={items} />);
  expect(subscriberMenu.find("Item").length).toBe(3);
});

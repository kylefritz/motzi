require("../configure_enzyme");
import React from "react";
import { mount } from "enzyme";

import mockMenuJson from "./mockMenuJson";
import Items, { DayButton, Item } from "menu/Items";
import { SettingsContext } from "menu/Contexts";

test("items", () => {
  const { menu } = mockMenuJson();
  const { items } = menu;

  const marketplace = mount(
    <SettingsContext.Provider value={{ showCredits: false }}>
      <Items marketplace items={items} />
    </SettingsContext.Provider>
  );
  const numMarketPlace = items.filter(({ marketplace }) => marketplace).length;
  expect(marketplace.find("Item")).toHaveLength(numMarketPlace);

  const subscriberMenu = mount(
    <SettingsContext.Provider value={{ showCredits: true }}>
      <Items items={items} />
    </SettingsContext.Provider>
  );
  const numSubscriber = items.filter(({ subscriber }) => subscriber).length;
  expect(subscriberMenu.find("Item")).toHaveLength(numSubscriber);

  expect(numSubscriber).not.toBe(numMarketPlace);
  expect(numSubscriber).toBeGreaterThan(1);
  expect(numMarketPlace).toBeGreaterThan(1);
});

test("day1day2", () => {
  const render = (props) =>
    mount(
      <SettingsContext.Provider value={{ showCredits: true }}>
        <Item onChange={true} {...props} />
      </SettingsContext.Provider>
    );
  const expectButtons = (props) => expect(render(props).find("button"));

  expectButtons({ day1: true, day2: true }).toHaveLength(2);
  expectButtons({ day1: true, day2: false }).toHaveLength(1);
  expectButtons({ day1: false, day2: true }).toHaveLength(1);
  expectButtons({ day1: false, day2: false }).toHaveLength(0);
});

test("remaining deadline", () => {
  const render = (props) =>
    mount(<DayButton day="Thursday" btn="primary" {...props} />);

  expect(render({ remaining: 4 }).text()).toMatch("4 left");
  expect(render({ remaining: 4 }).find("button").prop("disabled")).toBe(
    undefined
  );
  expect(render({ remaining: 0 }).find("button").prop("disabled")).toBe(true);

  expect(render({ isPastDeadline: true }).find("button").prop("disabled")).toBe(
    true
  );
});

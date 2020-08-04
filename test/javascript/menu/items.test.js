require("../configure_enzyme");
import React from "react";
import { mount } from "enzyme";

import mockMenuJson from "./mockMenuJson";
import Items, { Item } from "menu/Items";
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

// test("day1day2", () => {
//   const render = (props) =>
//     mount(<Item onChange={true} day1={true} day2={true} {...props} />);
//   const expectButtons = (props) => expect(render(props).find("button"));

//   expectButtons({ remainingDay1: true, remainingDay2: true }).toHaveLength(2);
//   console.log(render({ remainingDay1: true, remainingDay2: false }).debug());
//   expectButtons({ remainingDay1: true, remainingDay2: false }).toHaveLength(1);
//   expectButtons({ remainingDay1: false, remainingDay2: true }).toHaveLength(1);
//   expectButtons({ remainingDay1: false, remainingDay2: false }).toHaveLength(0);
// });

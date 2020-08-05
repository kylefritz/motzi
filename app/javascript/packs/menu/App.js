import React, { useState, useEffect } from "react";
import axios from "axios";
import * as Sentry from "@sentry/browser";
import queryString from "query-string";
import _ from "lodash";

import { getDayContext, DayContext, SettingsContext } from "./Contexts";
import Menu from "./Menu";
import Marketplace from "./Marketplace";
import Order from "./Order";

function Layout({
  bundles,
  error,
  handleCreateOrder,
  isEditingOrder,
  menu,
  order,
  setIsEditingOrder,
  user,
}) {
  if (error) {
    return (
      <>
        <h2 className="mt-5">{error}</h2>
        <p className="text-center">Sorry. Maybe try again or try back later?</p>
      </>
    );
  }

  if (!menu) {
    return <h2 className="mt-5">loading...</h2>;
  }

  const { day2Closed } = getDayContext();

  if (order && !isEditingOrder) {
    const handleEditOrder =
      menu.isCurrent && !day2Closed ? () => setIsEditingOrder(true) : null;
    return (
      <Order
        {...{
          user,
          order,
          menu,
          bundles,
          onEditOrder: handleEditOrder,
        }}
      />
    );
  }

  if (!user) {
    return <Marketplace {...{ menu, onCreateOrder: handleCreateOrder }} />;
  }

  return (
    <Menu
      {...{
        user,
        order,
        menu,
        bundles,
        onCreateOrder: handleCreateOrder,
      }}
    />
  );
}

export default function App() {
  const [data, setData] = useState({}); // expect: menu, user, order
  const [error, setError] = useState();
  const [isEditingOrder, setIsEditingOrder] = useState(false);
  const { uid, ignoredeadline: ignoreDeadline } = queryString.parse(
    location.search
  );

  const fetchMenu = () => {
    let params = { uid };
    const id = _.get(location.pathname.match(/menus\/(.*)/), 1);
    const menuPath = id ? `/menus/${id}.json` : "/menu.json";
    axios
      .get(menuPath, { params })
      .then(({ data: newData }) => {
        setData(newData); // expect: menu, user, order
        const { user } = newData;
        Sentry.configureScope((scope) => scope.setUser(user));
      })
      .catch((err) => {
        console.error("cant load menu", err);
        Sentry.captureException(err);
        setError("We can't load the menu");
      });
  };

  useEffect(fetchMenu, []);

  const handleCreateOrder = (order) => {
    const orderId = _.get(data, "order.id");

    const method = orderId ? "put" : "post";
    const url = orderId ? `/orders/${orderId}.json` : "/orders.json";
    console.debug("saving order", method, url, order);

    return axios({ method, url, data: order })
      .then(({ data: newData }) => {
        setData(newData); // expect: menu, user, order
        setIsEditingOrder(false);
        console.log("save_order success", newData);
        window.scrollTo(0, 0);
      })
      .catch((err) => {
        const { message } = err.response.data || {};
        console.error("Couldn't create order", err, err.response.data);
        window.alert(`Couldn't create order: ${message || err}`);
        Sentry.captureException(err);
      });
  };
  const { menu, bundles, user } = data;
  const {
    day1,
    day1Deadline,
    day1DeadlineDay,
    day2,
    day2Deadline,
    day2DeadlineDay,
    enablePayWhatYouCan,
  } = menu || {};

  return (
    <SettingsContext.Provider
      value={{
        enablePayWhatYouCan,
        bundles,
        onRefresh: fetchMenu,
        showCredits: !_.isNil(user), // could push this setting into marketplace vs menu?
      }}
    >
      <DayContext.Provider
        value={{
          day1,
          day1Deadline,
          day1DeadlineDay,
          day2,
          day2Deadline,
          day2DeadlineDay,
          ignoreDeadline,
        }}
      >
        <Layout
          {...{
            ...data,
            error,
            fetchMenu,
            handleCreateOrder,
            isEditingOrder,
            setIsEditingOrder,
          }}
        />
      </DayContext.Provider>
    </SettingsContext.Provider>
  );
}

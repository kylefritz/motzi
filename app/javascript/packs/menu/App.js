import React, { useState, useEffect } from "react";
import axios from "axios";
import * as Sentry from "@sentry/browser";
import queryString from "query-string";
import _ from "lodash";

import { UserContext } from "./Contexts";
import Menu from "./Menu";
import Marketplace from "./Marketplace";
import Order from "./Order";
import Preview from "./Preview";
import { pastDeadline } from "./pastDeadline";

export function munge(menu) {
  const { items } = menu;
  const menuItems = _.keyBy(items, (i) => i.id);
  // identify _skip_ item and _payItForward_ item
  // filter them out of the collection of _regular_ items
  return {
    ...menu,
    skip: menuItems[0] || {},
    payItForward: menuItems[-1] || {},
    items: items.filter(({ id }) => id !== 0 && id !== -1),
  };
}

function Layout({
  error,
  fetchMenu,
  handleCreateOrder,
  ignoredeadline,
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

  menu = munge(menu);

  const deadlineExceeded = pastDeadline(menu.deadline) && !ignoredeadline;

  if (order && !isEditingOrder) {
    const handleEditOrder = deadlineExceeded
      ? null
      : () => setIsEditingOrder(true);
    return (
      <Order
        {...{
          user,
          order,
          menu,
          onRefreshUser: fetchMenu,
          onEditOrder: handleEditOrder,
        }}
      />
    );
  }

  if (deadlineExceeded || !menu.isCurrent) {
    return <Preview menu={menu} />;
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
        onCreateOrder: handleCreateOrder,
        onRefreshUser: fetchMenu,
      }}
    />
  );
}

export default function App() {
  const [data, setData] = useState({}); // expect: menu, user, order
  const [error, setError] = useState();
  const [isEditingOrder, setIsEditingOrder] = useState(false);
  const { uid, ignoredeadline } = queryString.parse(location.search);

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
  const { user } = data;

  return (
    <UserContext.Provider value={user}>
      <Layout
        {...{
          ...data,
          error,
          fetchMenu,
          handleCreateOrder,
          ignoredeadline,
          isEditingOrder,
          setIsEditingOrder,
        }}
      />
    </UserContext.Provider>
  );
}

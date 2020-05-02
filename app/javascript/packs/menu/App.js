import React, { useState, useEffect } from "react";
import axios from "axios";
import * as Sentry from "@sentry/browser";
import queryString from "query-string";
import _ from "lodash";
import moment from "moment";

import Menu from "./Menu";
import Order from "./Order";
import Preview from "./Preview";

export default function App() {
  const [data, setData] = useState({}); // expect: menu, user, order
  const [error, setError] = useState();
  const { uid, ignoredeadline } = queryString.parse(location.search);

  const fetchMenu = () => {
    let params = { uid };
    const id = _.get(location.pathname.match(/menu\/(.*)/), 1);
    const menuPath = id ? `/menu/${id}.json` : "/menu.json";
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
    if (data.order) {
      window.alert(
        "Weird. This web site thinks you already placed an order. Refresh the page?!"
      );
      return;
    }

    console.log("creating order", order);
    axios
      .post("/orders.json", order)
      .then(({ data: newData }) => {
        setData(newData); // expect: menu, user, order
        console.debug("created order", newData);
        window.scrollTo(0, 0);
      })
      .catch((err) => {
        const { message } = err.response.data || {};
        console.error("Couldn't create order", err, err.response.data);
        window.alert(`Couldn't create order: ${message || err}`);
        Sentry.captureException(err);
      });
  };

  const { menu, user, order } = data;
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

  if (order) {
    return <Order {...{ user, order, menu, onRefreshUser: fetchMenu }} />;
  }

  const pastDeadline = moment() > moment(menu.deadline);
  if (!user || (!ignoredeadline && pastDeadline)) {
    return <Preview {...{ order, menu }} />;
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

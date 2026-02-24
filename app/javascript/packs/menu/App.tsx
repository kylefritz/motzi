import React, { useState, useEffect } from "react";
import axios from "axios";
import * as Sentry from "@sentry/browser";
import queryString from "query-string";
import _ from "lodash";

import { DayContext, SettingsContext } from "./Contexts";
import Layout from "./Layout";
import MenuTabs from "./MenuTabs";
import type {
  CreditBundle,
  Menu as MenuType,
  MenuOrder,
  MenuOrderRequest,
  MenuResponse,
  MenuUser,
  MarketplaceOrderRequest,
} from "../../types/api";

export default function App() {
  const [data, setData] = useState<MenuResponse | null>(null); // expect: menu, user, order
  const [error, setError] = useState<string | undefined>();
  const [isEditingOrder, setIsEditingOrder] = useState(false);
  const { uid, ignoredeadline: ignoreDeadline } = queryString.parse(
    location.search
  ) as { uid?: string; ignoredeadline?: string };

  const fetchMenu = () => {
    let params = { uid };
    const id = _.get(location.pathname.match(/menus\/(.*)/), 1);
    const menuPath = id ? `/menus/${id}.json` : "/menu.json";
    axios
      .get<MenuResponse>(menuPath, { params })
      .then(({ data: newData }) => {
        setData(newData); // expect: menu, user, order
        const { user } = newData;
        Sentry.configureScope((scope) =>
          scope.setUser(user ? { id: user.id, email: user.email } : null)
        );
      })
      .catch((err) => {
        console.error("cant load menu", err);
        Sentry.captureException(err);
        setError("We can't load the menu");
      });
  };

  useEffect(fetchMenu, []);

  const handleCreateOrder = (
    order: MenuOrderRequest | MarketplaceOrderRequest
  ) => {
    const orderId = _.get(data, "order.id");

    const method: "put" | "post" = orderId ? "put" : "post";
    const url = orderId ? `/orders/${orderId}.json` : "/orders.json";
    console.debug("saving order", method, url, order);

    return axios<MenuResponse>({ method, url, data: order })
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

  const handleCreateHolidayOrder = (
    order: MenuOrderRequest | MarketplaceOrderRequest
  ) => {
    const holidayOrderId = _.get(data, "holidayOrder.id");
    const method: "put" | "post" = holidayOrderId ? "put" : "post";
    const url = holidayOrderId
      ? `/orders/${holidayOrderId}.json`
      : "/orders.json";
    const orderWithMenu = holidayMenu
      ? { ...order, menu_id: holidayMenu.id }
      : order;
    console.debug("saving holiday order", method, url, orderWithMenu);

    return axios<MenuResponse>({ method, url, data: orderWithMenu })
      .then(({ data: newData }) => {
        setData(newData);
        console.log("save_holiday_order success", newData);
        window.scrollTo(0, 0);
      })
      .catch((err) => {
        const { message } = err.response.data || {};
        console.error("Couldn't create holiday order", err, err.response.data);
        window.alert(`Couldn't create holiday order: ${message || err}`);
        Sentry.captureException(err);
      });
  };

  const menu = data?.menu || null;
  const bundles = data?.bundles || [];
  const user = data?.user || null;
  const order = data?.order || null;
  const holidayMenu = data?.holidayMenu || null;
  const holidayOrder = data?.holidayOrder || null;
  const { orderingDeadlineText, enablePayWhatYouCan } = menu || {};

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
          orderingDeadlineText, // TODO: this needs fixed
          ignoreDeadline,
        }}
      >
        {holidayMenu ? (
          <MenuTabs
            bundles={bundles}
            handleCreateRegularOrder={handleCreateOrder}
            handleCreateHolidayOrder={handleCreateHolidayOrder}
            isEditingOrder={isEditingOrder}
            regularMenu={menu}
            regularOrder={order}
            holidayMenu={holidayMenu}
            holidayOrder={holidayOrder}
            setIsEditingOrder={setIsEditingOrder}
            user={user}
          />
        ) : (
          <Layout
            bundles={bundles}
            error={error}
            handleCreateOrder={handleCreateOrder}
            isEditingOrder={isEditingOrder}
            menu={menu}
            order={order}
            setIsEditingOrder={setIsEditingOrder}
            user={user}
          />
        )}
      </DayContext.Provider>
    </SettingsContext.Provider>
  );
}

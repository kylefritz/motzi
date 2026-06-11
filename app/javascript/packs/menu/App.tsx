import React, { useState, useEffect } from "react";
import axios from "axios";
import queryString from "query-string";
import _ from "lodash";
import { reportException } from "../../lib/errorReporter";

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

// Network blips (no response at all) get retried before we report an error
// and give up — members on flaky mobile connections see them regularly.
const MENU_FETCH_RETRY_DELAYS_MS = [500, 1500];

export default function App() {
  const [data, setData] = useState<MenuResponse | null>(null); // expect: menu, user, order
  const [error, setError] = useState<string | undefined>();
  const [isEditingOrder, setIsEditingOrder] = useState(false);
  const { uid, ignoredeadline: ignoreDeadline, tab } = queryString.parse(
    location.search
  ) as { uid?: string; ignoredeadline?: string; tab?: string };

  const fetchMenu = () => {
    let params = { uid };
    const id = _.get(location.pathname.match(/menus\/(.*)/), 1);
    const menuPath = id ? `/menus/${id}.json` : "/menu.json";

    const attempt = (tryIndex: number) => {
      axios
        .get<MenuResponse>(menuPath, { params })
        .then(({ data: newData }) => {
          setData(newData); // expect: menu, user, order
        })
        .catch((err) => {
          const delay = MENU_FETCH_RETRY_DELAYS_MS[tryIndex];
          if (!err.response && delay !== undefined) {
            console.warn("menu fetch failed, retrying", tryIndex + 1, err);
            setTimeout(() => attempt(tryIndex + 1), delay);
            return;
          }
          console.error("cant load menu", err);
          reportException(err, {
            kind: "menu_fetch",
            attempts: tryIndex + 1,
            online: navigator.onLine,
          });
          setError("We can't load the menu");
        });
    };

    attempt(0);
  };

  useEffect(fetchMenu, []);

  const handleCreateOrder = (
    order: MenuOrderRequest | MarketplaceOrderRequest
  ) => {
    const orderId = _.get(data, "order.id");

    const method: "put" | "post" = orderId ? "put" : "post";
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
        const { message } = err.response?.data || {};
        console.error("Couldn't create order", err, err.response?.data);
        window.alert(`Couldn't create order: ${message || err}`);
        reportException(err, { kind: "create_order" });
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

    return axios({ method, url, data: orderWithMenu })
      .then(({ data: newData }) => {
        setData(newData);
        console.log("save_holiday_order success", newData);
        window.scrollTo(0, 0);
      })
      .catch((err) => {
        const { message } = err.response?.data || {};
        console.error("Couldn't create holiday order", err, err.response?.data);
        window.alert(`Couldn't create holiday order: ${message || err}`);
        reportException(err, { kind: "create_holiday_order" });
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
            initialTab={tab}
          />
        )}
      </DayContext.Provider>
    </SettingsContext.Provider>
  );
}

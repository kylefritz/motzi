import React, { useState, useEffect } from "react";
import axios from "axios";
import * as Sentry from "@sentry/browser";
import queryString from "query-string";
import _ from "lodash";

import { getDeadlineContext, DayContext, SettingsContext } from "./Contexts";
import Menu from "./Menu";
import Marketplace from "./Marketplace";
import Order from "./Order";
import type {
  CreditBundle,
  Menu as MenuType,
  MenuOrder,
  MenuOrderRequest,
  MenuResponse,
  MenuUser,
  MarketplaceOrderRequest,
} from "../../types/api";

type LayoutProps = {
  bundles: CreditBundle[];
  error?: string;
  handleCreateOrder: (
    order: MenuOrderRequest | MarketplaceOrderRequest
  ) => Promise<unknown>;
  isEditingOrder: boolean;
  menu: MenuType | null;
  order: MenuOrder | null;
  setIsEditingOrder: React.Dispatch<React.SetStateAction<boolean>>;
  user: MenuUser | null;
};

function Layout({
  bundles,
  error,
  handleCreateOrder,
  isEditingOrder,
  menu,
  order,
  setIsEditingOrder,
  user,
}: LayoutProps) {
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

  const orderingClosed = getDeadlineContext().allClosed(menu);

  if (order && !isEditingOrder) {
    const handleEditOrder =
      menu.isCurrent && !orderingClosed ? () => setIsEditingOrder(true) : null;
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
  const menu = data?.menu || null;
  const bundles = data?.bundles || [];
  const user = data?.user || null;
  const order = data?.order || null;
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
        <Layout
          {...{
            bundles,
            error,
            handleCreateOrder,
            isEditingOrder,
            menu,
            order,
            setIsEditingOrder,
            user,
          }}
        />
      </DayContext.Provider>
    </SettingsContext.Provider>
  );
}

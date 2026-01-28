import React, { useEffect, useState } from "react";
import axios from "axios";
import * as Sentry from "@sentry/browser";
import _ from "lodash";

import Layout from "./Layout";
import { ApiContext, BuilderApi } from "./Context";
import type {
  AdminItem,
  AdminItemsResponse,
  AdminMenuBuilderResponse,
} from "../../types/api";

const menuId = _.get(location.pathname.match(/menus\/(.*)/), 1) as
  | string
  | undefined;

export default function MenuBuilder() {
  const [menu, setMenu] = useState<AdminMenuBuilderResponse | null>(null);
  const [allItems, setAllItems] = useState<AdminItem[] | null>(null);
  const [error, setError] = useState<string | undefined>();

  function loadMenu() {
    axios
      .get<AdminMenuBuilderResponse>(`/admin/menus/${menuId}/menu_builder.json`)
      .then(({ data: menu }) => {
        setMenu(menu);
        setError(undefined);
      })
      .catch((error) => {
        console.error("cant load menu", error);
        Sentry.captureException(error);
        setError("We can't load the menu");
      });
  }

  const api: BuilderApi = {
    item: {
      add: (item) => {
        const json = { ...item, menuId };
        console.log("add item", json);
        return axios
          .post(`/admin/menus/${menuId}/item.json`, json)
          .then(loadMenu);
      },

      remove: (itemId) => {
        console.log("remove item", itemId);
        return axios
          .post(`/admin/menus/${menuId}/remove_item.json`, { itemId })
          .then(({ data: menu }) => setMenu(menu));
      },
    },
    menuItem: {
      update: (menuItemId, json) => {
        console.log("update menu item", json);
        return axios
          .patch(`/admin/menu_items/${menuItemId}.json`, json)
          .then(loadMenu);
      },
    },
    pickupDay: {
      add: (pickupDay) => {
        const json = { ...pickupDay, menuId };
        console.log("add pickupDay", json);
        return axios.post("/admin/pickup_days.json", json).then(loadMenu);
      },

      remove: (pickupDayId) => {
        console.log("rm pickupDay", pickupDayId);
        return axios
          .delete(`/admin/pickup_days/${pickupDayId}.json`)
          .then(loadMenu);
      },
    },
    menuItemPickupDay: {
      add: ({ menuItemId, pickupDayId }) => {
        const json = { menuItemId, pickupDayId };

        console.log("add MenuItem PickupDay", json);
        return axios
          .post("/admin/menu_item_pickup_days.json", json)
          .then(loadMenu);
      },

      remove: ({ menuItemId, pickupDayId }) => {
        const json = { menuItemId, pickupDayId };
        console.log("remove MenuItem PickupDay", json);
        return axios
          .post(`/admin/menus/${menuId}/remove_menu_item_pickup_day.json`, json)
          .then(({ data: menu }) => setMenu(menu));
      },

      updateLimit: ({ id, limit }) => {
        const json = { limit };

        console.log("update MenuItem PickupDay", json);
        return axios
          .patch(`/admin/menu_item_pickup_days/${id}.json`, json)
          .then(loadMenu);
      },
    },
  };

  useEffect(() => {
    loadMenu();

    // load items
    // TODO: why side load? add to menu request?
    axios
      .get<AdminItemsResponse>(`/admin/items.json`)
      .then(({ data: { items } }) => {
        setAllItems(items);
      })
      .catch((error) => {
        console.error("cant load items", error);
        Sentry.captureException(error);
        setError("We can't load the  items");
      });
  }, []);

  if (error) {
    return <h2>{error} :(</h2>;
  }
  if (!allItems || !menu) {
    return <h2>Loading</h2>;
  }

  return (
    <ApiContext.Provider value={api}>
      <Layout {...{ menu, allItems }} />
    </ApiContext.Provider>
  );
}

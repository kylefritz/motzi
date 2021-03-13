import React, { useEffect, useState } from "react";
import axios from "axios";
import * as Sentry from "@sentry/browser";
import _ from "lodash";

import Layout from "./Layout";

const menuId = _.get(location.pathname.match(/menus\/(.*)/), 1);

export default function MenuBuilder() {
  const [menu, setMenu] = useState();
  const [allItems, setAllItems] = useState();
  const [error, setError] = useState();

  function loadMenu() {
    axios
      .get(`/admin/menus/${menuId}/menu_builder.json`)
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

  function handleAddItem(item) {
    const json = { ...item, menuId };
    console.log("add item", json);
    return axios.post(`/admin/menus/${menuId}/item.json`, json).then(loadMenu);
  }

  function handleRemoveItem(itemId) {
    console.log("remove item", itemId);
    return axios
      .post(`/admin/menus/${menuId}/remove_item.json`, { itemId })
      .then(({ data: menu }) => setMenu(menu));
  }

  function handleAddPickupDay(pickupDay) {
    const json = { ...pickupDay, menuId };
    console.log("add pickupDay", json);
    return axios.post("/admin/pickup_days.json", json).then(loadMenu);
  }

  function handleRemovePickupDay(pickupDayId) {
    console.log("rm pickupDay", pickupDayId);
    return axios
      .delete(`/admin/pickup_days/${pickupDayId}.json`)
      .then(loadMenu);
  }

  function handleChangeMenuItemPickupDay({ menuItemId, pickupDayId }, add) {
    const method = add
      ? handleAddMenuItemPickupDay
      : handleRemoveMenuItemPickupDay;
    return method({ menuItemId, pickupDayId });
  }

  function handleAddMenuItemPickupDay({ menuItemId, pickupDayId }) {
    const json = { menuItemId, pickupDayId };

    console.log("add MenuItem PickupDay", json);
    return axios.post("/admin/menu_item_pickup_days.json", json).then(loadMenu);
  }

  function handleRemoveMenuItemPickupDay({ menuItemId, pickupDayId }) {
    const json = { menuItemId, pickupDayId };
    console.log("remove MenuItem PickupDay", json);
    return axios
      .post(`/admin/menus/${menuId}/remove_menu_item_pickup_day.json`, json)
      .then(({ data: menu }) => setMenu(menu));
  }

  function handleUpdateMenuItemPickupDay({ id, limit }) {
    const json = { limit };

    console.log("update MenuItem PickupDay", json);
    return axios
      .patch(`/admin/menu_item_pickup_days/${id}.json`, json)
      .then(loadMenu);
  }

  useEffect(() => {
    loadMenu();

    // load items
    // TODO: why side load? add to menu request?
    axios
      .get(`/admin/items.json`)
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
    <Layout
      {...{
        menu,
        allItems,
        handleRemoveItem,
        handleAddItem,
        handleAddPickupDay,
        handleRemovePickupDay,
        handleChangeMenuItemPickupDay,
        handleUpdateMenuItemPickupDay,
      }}
    />
  );
}

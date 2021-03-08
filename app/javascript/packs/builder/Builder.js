import React, { useEffect, useState } from "react";
import axios from "axios";
import * as Sentry from "@sentry/browser";
import _ from "lodash";

import Layout from "./Layout";

const menuId = _.get(location.pathname.match(/menus\/(.*)/), 1);

export default function MenuBuilder() {
  const [menuItems, setMenuItems] = useState();
  const [allItems, setAllItems] = useState();
  const [error, setError] = useState();

  function loadMenu() {
    axios
      .get(`/admin/menus/${menuId}/menu_builder.json`)
      .then(({ data: { items } }) => {
        setMenuItems(items);
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
    return axios.post("/admin/menu_items.json", json).then(loadMenu);
  }

  function handleRemoveItem(itemId) {
    console.log("remove item", itemId);
    return axios({
      method: "delete",
      data: { itemId },
      url: `/admin/menus/${menuId}/item.json`,
    }).then(loadMenu);
  }
  useEffect(() => {
    loadMenu();

    // load items
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
  if (!allItems || !menuItems) {
    return <h2>Loading</h2>;
  }

  return (
    <Layout {...{ menuItems, allItems, handleRemoveItem, handleAddItem }} />
  );
}

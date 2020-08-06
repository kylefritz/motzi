import React from "react";
import axios from "axios";
import * as Sentry from "@sentry/browser";
import _ from "lodash";

import MenuItem from "./Item";
import Adder from "./Adder";

export default class MenuBuilder extends React.Component {
  constructor(props) {
    super(props);
    const menuId = _.get(location.pathname.match(/menus\/(.*)/), 1);
    this.state = { menuId };
  }

  loadMenu() {
    const { menuId } = this.state;
    axios
      .get(`/admin/menus/${menuId}/menu_items.json`)
      .then(({ data: { items } }) => {
        this.setState({ menuItems: items });
      })
      .catch((error) => {
        console.error("cant load menu", error);
        Sentry.captureException(error);
        this.setState({ error: "We can't load the menu" });
      });
  }

  componentDidMount() {
    this.loadMenu();

    axios
      .get(`/admin/items.json`)
      .then(({ data: { items } }) => {
        this.setState({ items });
      })
      .catch((error) => {
        console.error("cant load items", error);
        Sentry.captureException(error);
        this.setState({ error: "We can't load the items" });
      });
  }

  handleAddItem(props) {
    const { menuId } = this.state;
    const json = { ...props, menuId };
    console.log("add item", json);
    axios.post("/admin/menu_items.json", json).then(() => this.loadMenu());
  }

  handleRemoveItem(itemId) {
    const { menuId } = this.state;
    console.log("remove item", itemId);
    axios({
      method: "delete",
      data: { itemId },
      url: `/admin/menus/${menuId}/item.json`,
    }).then(() => this.loadMenu());
  }

  render() {
    const { error, menuItems, items: allItems } = this.state || {};
    if (error) {
      return <h2>{error} :(</h2>;
    }
    if (!allItems || !menuItems) {
      return <h2>Loading</h2>;
    }

    return (
      <div className="menu-builder">
        <h4>Items</h4>
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Marketplace?</th>
              <th>Subscriber?</th>
              <th>Day 1?</th>
              <th>Day 1 Limit</th>
              <th>Day 2?</th>
              <th>Day 2 Limit</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {menuItems.map((i) => (
              <MenuItem
                key={i.id}
                {...i}
                onRemove={this.handleRemoveItem.bind(this)}
              />
            ))}
          </tbody>
        </table>
        {items.length == 0 && (
          <p>
            <em>no items</em>
          </p>
        )}
        <Adder
          items={allItems}
          not={menuItems.map(({ name }) => name)}
          onAdd={(item) => this.handleAddItem(item)}
        />
      </div>
    );
  }
}

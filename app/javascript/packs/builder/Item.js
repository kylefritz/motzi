import React from "react";
import _ from "lodash";

export default class Item extends React.Component {
  handleRemove() {
    this.props.onRemove(this.props.id);
  }
  render() {
    const { menuItemId, name, subscriber, marketplace, day1, day2 } =
      this.props || {};
    return (
      <tr>
        <td>{name}</td>
        <td>{marketplace ? "" : "no"}</td>
        <td>{subscriber ? "" : "no"}</td>
        <td>{day1 ? "" : "no"}</td>
        <td>{day2 ? "" : "no"}</td>
        <td>
          <a href={`/admin/menu_items/${menuItemId}`} target="_blank">
            Edit
          </a>
          {<button onClick={this.handleRemove.bind(this)}>x</button>}
        </td>
      </tr>
    );
  }
}

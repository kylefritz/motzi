import React from "react";
import _ from "lodash";

export default class Item extends React.Component {
  handleRemove(event) {
    this.props.onRemove(this.props.id);
  }
  render() {
    const { id, name, subscriberOnly, day1, day2 } = this.props || {};
    return (
      <tr>
        <td>{name}</td>
        <td>{subscriberOnly ? "yes" : ""}</td>
        <td>{day1 ? "" : "no"}</td>
        <td>{day2 ? "" : "no"}</td>
        <td>
          {id > 0 && <button onClick={this.handleRemove.bind(this)}>x</button>}
        </td>
      </tr>
    );
  }
}

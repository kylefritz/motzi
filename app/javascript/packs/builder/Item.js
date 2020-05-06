import React from "react";
import _ from "lodash";

export default class Item extends React.Component {
  handleRemove(event) {
    this.props.onRemove(this.props.id);
  }
  render() {
    const { id, name } = this.props || {};
    return (
      <tr>
        <td>{name}</td>
        <td>
          {id > 0 && <button onClick={this.handleRemove.bind(this)}>x</button>}
        </td>
      </tr>
    );
  }
}

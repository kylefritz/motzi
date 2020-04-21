import React from "react";

import Quantity from "./Quantity";

export default class AddOn extends React.Component {
  state = { isChecked: false, quantity: 0 };
  constructor(props) {
    super(props);
    this.cbRef = React.createRef();
  }
  handleChanged() {
    const isChecked = this.cbRef.current.checked;
    this.setState({ isChecked });
    if (isChecked) {
      this.handleQuantityChanged(1);
    } else {
      // reset
      this.handleQuantityChanged(0);
    }
  }
  handleQuantityChanged(quantity) {
    this.setState({ quantity });
    this.props.onChange(quantity);
  }
  render() {
    const { name } = this.props;
    const { isChecked, quantity } = this.state;

    return (
      <div className="form-check mb-1">
        <label className="form-check-label">
          <input
            value={name}
            ref={this.cbRef}
            onChange={this.handleChanged.bind(this)}
            className="form-check-input"
            type="checkbox"
          />
          {isChecked && <strong className="pr-3">{quantity}x</strong>}
          {name}
        </label>
        {isChecked && (
          <div className="mb-4">
            <Quantity onChange={this.handleQuantityChanged.bind(this)} />
          </div>
        )}
      </div>
    );
  }
}

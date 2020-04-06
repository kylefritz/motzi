import React from "react";

export default class AddOn extends React.Component {
  constructor(props) {
    super(props);
    this.cbRef = React.createRef();
  }
  handleClick() {
    this.cbRef.current.checked = !this.cbRef.current.checked;
    this.handleChanged();
  }
  handleChanged() {
    this.props.onChange(this.cbRef.current.checked);
  }
  render() {
    const { name } = this.props;

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
          {name}
        </label>
      </div>
    );
  }
}

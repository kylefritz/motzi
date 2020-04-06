import React from "react";

export default class Item extends React.Component {
  constructor(props) {
    super(props);
    this.cbRef = React.createRef();
  }
  handleClickToCheck() {
    this.cbRef.current.checked = true;
    this.handleChanged();
  }
  handleChanged() {
    if (this.props.onChange) {
      this.props.onChange(this.cbRef.current.checked);
    }
  }
  render() {
    const { name, description, image, onChange } = this.props;

    return (
      <div className="col-6 mb-5">
        <img
          src={image}
          className="img-fluid"
          style={{ objectFit: "contain" }}
          onClick={this.handleClickToCheck.bind(this)}
        />
        <div className="form-check">
          <label className="form-check-label">
            <input
              value={name}
              ref={this.cbRef}
              onChange={this.handleChanged.bind(this)}
              className={`form-check-input ${onChange ? "" : "d-none"}`}
              type="radio"
              name="item"
            />
            {name} <br />
            <small>{description}</small>
          </label>
        </div>
      </div>
    );
  }
}

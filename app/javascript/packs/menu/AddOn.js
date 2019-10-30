import React from 'react'

export default class AddOn extends React.Component {
  constructor(props) {
    super(props);
    this.cbRef = React.createRef();
  }
  handleClick() {
    this.cbRef.current.checked = !this.cbRef.current.checked
    this.handleChanged()
  }
  handleChanged() {
    this.props.onChange(this.cbRef.current.checked)
  }
  render() {
    const { name, description, image } = this.props;

    return (
      <div className="form-check mb-1">
        <input value={name} ref={this.cbRef} onChange={this.handleChanged.bind(this)}
          className="form-check-input" type="checkbox" />
        <label className="form-check-label">
          {name}
        </label>
      </div>
    )
  }
}
import React from 'react'

export default class Item extends React.Component {
  constructor(props) {
    super(props);
    this.cbRef = React.createRef();
  }
  handleClickToCheck() {
    this.cbRef.current.checked = true
    this.handleChanged()
  }
  handleChanged() {
    this.props.onChange(this.cbRef.current.checked)
  }
  render() {
    const { name, description, image } = this.props;

    return (
      <div className="col-6 mb-5">
        <img src={image} className="img-fluid" style={{ objectFit: 'contain' }} onClick={this.handleClickToCheck.bind(this)} />
        <div className="form-check">
          <label className="form-check-label">
            <input className="form-check-input" type="radio" name="item" value={name} ref={this.cbRef} onChange={this.handleChanged.bind(this)} />
            {/* technically you cant put an h6 inside of a label but this is working fine for us */}
            {name} <br />
            <small>{description}</small>
          </label>
        </div>
      </div>
    )
  }
}

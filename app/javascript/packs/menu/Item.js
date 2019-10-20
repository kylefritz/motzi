import React from 'react'

export default class Item extends React.Component {
  constructor(props) {
    super(props);
    this.cbRef = React.createRef();
  }
  handleClick() {
    this.cbRef.current.checked = true
    this.props.onChange(this.cbRef.current.checked)
  }
  handleChanged() {
    this.props.onChange(this.cbRef.current.checked)
  }
  render() {
    const { name, description, image } = this.props;

    return (
      <div className="col-6">
        <div className="form-check">
          <input className="form-check-input" type="radio" name="item" value={name} ref={this.cbRef} onChange={this.handleChanged.bind(this)} />
          <label className="form-check-label">
            {/* technically you cant put an h6 inside of a label but this is working fine for us */}
            <h6>{name}</h6>
            <div onClick={this.handleClick.bind(this)}>{description}</div>
            <img src={image} className="img-fluid" style={{ objectFit: 'contain' }} onClick={this.handleClick.bind(this)} />
          </label>
        </div>
      </div>
    )
  }
}

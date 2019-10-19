import React from 'react'

export default class AddOn extends React.Component {
  constructor(props) {
    super(props);
    this.cbRef = React.createRef();
  }
  handleClick() {
    this.cbRef.current.checked = !this.cbRef.current.checked
  }
  render() {
    const { name, description, image } = this.props;

    return (
      <div className="col-6">
        <div className="form-check">
          <input className="form-check-input" type="checkbox" name="items" value={name} ref={this.cbRef} />
          <label className="form-check-label" for="exampleRadios1">
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

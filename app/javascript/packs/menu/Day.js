import React from 'react'
import _ from 'lodash'

export default class Day extends React.Component {
  constructor(props) {
    super(props);
    this.cbRef = React.createRef();
  }
  handleClickToCheck() {
    this.cbRef.current.checked = true
    this.handleChanged()
  }
  handleChanged() {
    if (this.props.onChange){
      this.props.onChange(this.props.name);
    }
  }
  render() {
    const { name, description, onChange, checked } = this.props;

    return (
      <div className="col-6 mb-5">
        <div className="form-check">
          <label className="form-check-label">
            <input value={name} ref={this.cbRef} onChange={this.handleChanged.bind(this)}
              className={`form-check-input ${onChange ? '' : 'd-none'}`} type="radio" name="day" defaultChecked={checked} />
            {_.capitalize(name)} <br />
            <small>{description}</small>
          </label>
        </div>
      </div>
    )
  }
}

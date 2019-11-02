import React from 'react'
import _ from 'lodash'

export default class Item extends React.Component {
  handleRemove(event) {
    this.props.onRemove(this.props.menuItemId)
  }
  render() {
    const { name, isAddOn } = this.props || {}
    return (
      <li>
        {name}{" "}<button onClick={this.handleRemove.bind(this)}>x</button>
      </li>
    )
  }
}

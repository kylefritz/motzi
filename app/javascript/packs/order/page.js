import React from 'react'

import PlaceOrder from './PlaceOrder.js'

export class Page extends React.Component {
  constructor(props) {
    super(props)
    this.state = { count: 0 }
  }
  handleClick() {
    const { count } = this.state
    this.setState({ count: count + 1 })
  }
  render() {
    return (
      <div>
        <h1>I'm a react app</h1>
        <div>yooo {this.props.name}</div>
        <div>I've been clicked {this.state.count}</div>
        <button onClick={this.handleClick.bind(this)}>Click me</button>
        <PlaceOrder />
      </div>
    )
  }
}

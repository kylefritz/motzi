import React from 'react'

import PlaceOrder from './PlaceOrder.js'

export default class App extends React.Component {
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
        <button onClick={this.handleClick.bind(this)}>This react app has been clicked {this.state.count} times</button>
        <PlaceOrder />
      </div>
    )
  }
}

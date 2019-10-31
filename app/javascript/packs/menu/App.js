import React from 'react'
import axios from 'axios'
import * as Sentry from '@sentry/browser';

import Order from './Order.js'
import Menu from './Menu.js'

export default class App extends React.Component {
  componentDidMount() {
    axios.get('/menu.json').then(({ data }) => {
      this.setState(data) // expect: menu, user, order
      const { user } = data
      Sentry.configureScope((scope) => scope.setUser(user))
    }).catch((error) => {
      console.error("cant load menu", error)
      Sentry.captureException(error)
      this.setState({ error: "We can't load the menu" })
    })
  }

  handleCreateOrder(order) {
    if (this.state.order) {
      window.alert("Weird. This web site thinks you already placed an order. Refresh the page?!")
      return
    }
    console.debug('creating order', order)
    axios.post('/orders.json', order).then(function (response) {
      console.debug('created order', response)
    }).catch((error) => {
      console.error("cant create order", error);
      window.alert("There was a problem submitting your order.")
      Sentry.captureException(error)
    });
  }

  render() {
    const { menu, user, order, error } = this.state || {};
    if (error) {
      return <>
        <h2 className="mt-5">{error}</h2>
        <p className="text-center">Sorry. Maybe try again or try back later?</p>
      </>
    }

    if (!menu) {
      return <h2 className="mt-5">loading...</h2>
    }

    if (order) {
      return <Order {...{ user, order, menu }} />
    }

    return <Menu {...{ user, order, menu, onCreateOrder: this.handleCreateOrder.bind(this) }} />
  }
}

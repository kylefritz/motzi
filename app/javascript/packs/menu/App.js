import React from 'react'
import axios from 'axios'
import * as Sentry from '@sentry/browser';
import queryString from 'query-string'
import _ from 'lodash'

import Menu from './Menu'
import Order from './Order'
import Preview from './Preview'

export default class App extends React.Component {
  componentDidMount() {
    this.fetchMenu();
  }

  fetchMenu(){
    const { uid } = queryString.parse(location.search)
    let params = { uid }
    const id = _.get(location.pathname.match(/menu\/(.*)/), 1)
    const menuPath = id ? `/menu/${id}.json` : '/menu.json'
    axios.get(menuPath, { params }).then(({ data }) => {
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
    axios.post('/orders.json', order).then(({ data }) => {
      this.setState(data) // expect: menu, user, order
      console.debug('created order', data)
      window.scrollTo(0, 0)
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
      return <Order {...{ user, order, menu, onRefreshUser: this.fetchMenu.bind(this) }} />
    }

    if (!user) {
      return <Preview {...{ order, menu }} />
    }

    return <Menu {...{ user, order, menu, onCreateOrder: this.handleCreateOrder.bind(this), onRefreshUser: this.fetchMenu.bind(this) }} />
  }
}

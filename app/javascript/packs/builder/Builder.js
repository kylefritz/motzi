import React from 'react'
import axios from 'axios'
import * as Sentry from '@sentry/browser'
import _ from 'lodash'

import Item from './Item'
import Adder from './Adder'

export default class App extends React.Component {
  constructor(props) {
    super(props)
    const menuId = _.get(location.pathname.match(/menus\/(.*)/), 1)
    this.state = { menuId }
  }

  loadMenu() {
    const { menuId } = this.state
    axios.get(`/menus/${menuId}.json`).then(({ data: { menu, user } }) => {
      this.setState({ menu })
      Sentry.configureScope((scope) => scope.setUser(user))
    }).catch((error) => {
      console.error("cant load menu", error)
      Sentry.captureException(error)
      this.setState({ error: "We can't load the menu" })
    })
  }

  componentDidMount() {
    this.loadMenu()

    axios.get(`/admin/items.json`).then(({ data: { items } }) => {
      this.setState({ items })
    }).catch((error) => {
      console.error("cant load items", error)
      Sentry.captureException(error)
      this.setState({ error: "We can't load the items" })
    })
  }

  handleAddItem({ itemId, isAddOn }) {
    const { menuId } = this.state
    const json = { itemId, isAddOn, menuId }
    console.log('add item', json)
    axios.post('/admin/menu_items.json', json).then(() => this.loadMenu())
  }

  handleRemoveMenuItem(removeMenuItemId) {
    console.log('delete menu_item', removeMenuItemId)
    axios.delete(`/admin/menu_items/${removeMenuItemId}.json`).then(() => this.loadMenu())
  }

  render() {
    const { error, items: allItems, menu } = this.state || {}
    if (error) {
      return <h2>{error} :(</h2>
    }
    if (!(allItems && menu)) {
      return <h2>Loading</h2>
    }
    const { addons, items } = menu
    const makeSet = (menuItems) => new Set(menuItems.map(({ name }) => name))

    return (
      <div className="menu-builder">
        <h4>Items</h4>
        <table>
          <tbody>
            {items.map(i => <Item key={i.menuItemId} {...i} onRemove={this.handleRemoveMenuItem.bind(this)} />)}
          </tbody>
        </table>
        {items.length == 0 && <p><em>no items</em></p>}
        <Adder items={allItems} not={makeSet(items)} onAdd={(itemId) => this.handleAddItem({ itemId, isAddOn: false })} />
        <hr />
        <h4>Add-ons</h4>
        <table>
          <tbody>
            {addons.map(i => <Item key={i.menuItemId} {...i} onRemove={this.handleRemoveMenuItem.bind(this)} />)}
          </tbody>
        </table>
        {addons.length == 0 && <p><em>no add-ons</em></p>}
        <Adder items={allItems} not={makeSet(addons)} onAdd={(itemId) => this.handleAddItem({ itemId, isAddOn: true })} />
      </div>
    )
  }
}

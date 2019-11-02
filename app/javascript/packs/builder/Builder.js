import React from 'react'
import axios from 'axios'
import * as Sentry from '@sentry/browser';
import _ from 'lodash'

import Item from './Item'

export default class App extends React.Component {
  constructor(props) {
    super(props)
    this.selectRef = React.createRef()
    this.cbRef = React.createRef()
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

    axios.get(`/items.json`).then(({ data: { items } }) => {
      this.setState({ items })
    }).catch((error) => {
      console.error("cant load items", error)
      Sentry.captureException(error)
      this.setState({ error: "We can't load the items" })
    })
  }

  handleAddItem(event) {
    const { menuId } = this.state

    const itemId = this.selectRef.current.value;
    const isAddOn = this.cbRef.current.checked;

    if (!itemId) {
      alert('Select an item')
      return
    }

    const json = { itemId, isAddOn, menuId }
    console.log('add item', json)
    axios.post('/admin/menu_items.json', json).then(() => {
      this.loadMenu()
      this.cbRef.current.checked = false
      this.selectRef.current.value = _.get(this.selectRef.current, [0, 'value'])
    })
  }

  handleRemoveMenuItem(removeMenuItemId) {
    console.log('delete menu_item', removeMenuItemId)
    axios.delete(`/admin/menu_items/${removeMenuItemId}.json`).then(() => {
      this.loadMenu()
    })
  }

  render() {
    const { error, items, menu } = this.state || {}
    if (error) {
      return <h2>{error} :(</h2>
    }
    if (!(items && menu)) {
      return <h2>Loading</h2>
    }

    return (<>
      <h4>Items</h4>
      <ul>
        {menu.items.map(i => <Item key={i.menuItemId} {...i} onRemove={this.handleRemoveMenuItem.bind(this)} />)}
      </ul>
      {menu.items.length == 0 && <p><em>no items</em></p>}

      <h4>Add-ons</h4>
      <ul>
        {menu.addons.map(i => <Item key={i.menuItemId} {...i} onRemove={this.handleRemoveMenuItem.bind(this)} />)}
      </ul>
      {menu.addons.length == 0 && <p><em>no add-ons</em></p>}

      <h4>Add item</h4>
      <select ref={this.selectRef}>
        {_.sortBy(items, ({ name }) => name).map(({ id, name }) => <option key={id} value={id}>{name}</option>)}
      </select>
      {" "}
      <label>
        <input type="checkbox" name="Is add on?" ref={this.cbRef} />
        Add on?
      </label>
      {" "}
      <button type="button" onClick={this.handleAddItem.bind(this)}>Add</button>
    </>)
  }
}

import React from 'react'
import axios from 'axios'
import * as Sentry from '@sentry/browser';

import Item from './Item.js'
import AddOn from './AddOn.js'
import BakersNote from './BakersNote.js'

export default class Menu extends React.Component {
  constructor(props) {
    super(props)
    this.state = { menu: null, selectedItem: null, addOns: new Set(), error: null }
  }
  componentDidMount() {
    axios.get('/menu.json').then(({ data }) => {
      this.setState(data) // expect: menu, user
    }).catch((error) => {
      console.error(error)
      Sentry.captureException(error)
      this.setState({ error: "We can't load the menu" })
    })
  }
  handleCreateOrder() {
    // TODO: handle already submitted
    // TODO: validate things are selected

    const { selectedItem, addOns, feedback, comments, user } = this.state;
    let order = { feedback, comments, items: [], uid: user.hashid }

    // TODO: handle skipping items
    if (selectedItem != 'skip') {
      order.items.push(selectedItem)
    }

    for (const addOn of addOns) {
      order.items.push(addOn)
    }
    console.debug('creating order', order)
    axios.post('/orders.json', order).then(function (response) {
      console.debug('created order', response)
    }).catch((error) => {
      console.error(error);
      window.alert("There was a problem submitting your order.")
      Sentry.captureException(error)
    });
  }
  handleItemSelected(itemId) {
    this.setState({ selectedItem: itemId })
  }
  handleAddOnSelected(itemId, isSelected) {
    let { addOns } = this.state;
    if (isSelected) {
      addOns.add(itemId)
    } else {
      addOns.delete(itemId)
    }
    this.setState({ addOns })
  }
  handleComments(e) {
    this.setState({ comments: e.target.value })
  }
  handleFeedback(e) {
    this.setState({ feedback: e.target.value })
  }
  render() {
    const { menu, user, error } = this.state;
    if (error) {
      return (
        <>
          <h2 className="mt-5">{error}</h2>
          <p className="text-center">Sorry. Maybe try again or try back later?</p>
        </>
      )
    }
    if (!menu) {
      return <h2 className="mt-5">loading...</h2>
    }
    const { name, bakersNote, items, addons } = menu;

    return (
      <>
        <p>Ordering for: {user.name}</p>
        <p>Credits remaining: {user.credits}</p>

        <h2>{name}</h2>

        <BakersNote {...{ bakersNote }} />

        <h5>We'd love your feedback on last week's loaf.</h5>
        <div className="row mt-3 mb-5">
          <div className="col">
            <input className="form-control" type="text" placeholder="What did you think?" onChange={this.handleFeedback.bind(this)} />
          </div>
        </div>

        <h5>Items</h5>
        <div className="row mt-3">
          {items.map(i => <Item key={i.id} {...i} onChange={() => this.handleItemSelected(i.id)} />)}
        </div>

        {!!addons.length && (
          <>
            <h5>Add-Ons</h5>
            <div className="row mt-3 mb-5">
              <div className="col">
                {addons.map(i => <AddOn key={i.id} {...i} onChange={(isSelected) => this.handleAddOnSelected(i.id, isSelected)} />)}
              </div>
            </div>
          </>)}

        <h5>Other comments?</h5>
        <div className="row mt-3 mb-5">
          <div className="col">
            <input placeholder="Your comments" onChange={this.handleComments.bind(this)}
              className="form-control" type="text" />
          </div>
        </div>

        <div className="row mt-3 mb-5">
          <div className="col">
            <button onClick={this.handleCreateOrder.bind(this)}
              className="btn btn-primary btn-lg btn-block" type="button">
              Submit Order
          </button>
          </div>
        </div>
      </>
    )
  }
}
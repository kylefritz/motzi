import React from 'react'
import axios from 'axios'

import Item from './Item.js'
import AddOn from './AddOn.js'
import BakersNote from './BakersNote.js'

export default class Menu extends React.Component {
  constructor(props) {
    super(props)
    this.state = { menu: null, selectedItem: null, addOns: new Set() }
  }
  componentDidMount() {
    axios.get('/menu.json').then(({ data }) => {
      this.setState(data) // expect: menu, user, credits
    }).catch((err) => {
      throw "couldn't get menu"
    })
  }
  handleCreateOrder() {
    // TODO: improve menu
    // * validate things are selected
    // * skipping weeks
    // * already submitted

    const { selectedItem, addOns, feedback, comments } = this.state;
    let order = { feedback, comments, items: [] };
    if (selectedItem != 'skip') {
      order.items.push(selectedItem)
    }

    for (const addOn of addOns) {
      order.items.push(addOn)
    }
    console.log('creating order', order)
    axios.post('/orders.json', order).then(function (response) {
      console.log(response);
    }).catch(function (error) {
      console.log(error);
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
    const { menu, user, credits } = this.state;
    if (!menu) {
      return <h2 className="mt-5">loading...</h2>
    }
    const { name, bakersNote, items, addons } = menu;

    return (
      <>
        <p>User: {user}</p>
        <p>Credits: {credits}</p>

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

          {/* skip */}
          <div className="col-6 mb-5">
            <div className="form-check">
              <label className="form-check-label">
                <input onChange={() => this.handleItemSelected("skip")}
                  name="item" value="skip" className="form-check-input" type="radio" />
                I'd like to skip this week, please credit me for a future week (limit 3 per 6 month period)
              </label>
            </div>
          </div>
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

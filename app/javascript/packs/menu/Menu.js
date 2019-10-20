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
    axios.get('/menu.json').then(({ data: menu }) => {
      this.setState({ menu })
    }).catch((err) => {
      throw "couldn't get menu"
    })
  }
  handleCreateOrder() {
    // TODO:
    // * skipping weeks
    // * validate things are selected
    // * dont let re-submit slash tell if already submitted

    const { selectedItem, addOns, feedback, comments } = this.state;
    let order = { feedback, comments, items: [] };
    if (selectedItem) {
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
    const { menu } = this.state;
    if (!menu) {
      return <div>loading...</div>;
    }
    const { name, bakersNote, items, addons } = menu;

    return (
      <div>
        <h2>{name}</h2>

        <BakersNote {...{ bakersNote }} />

        <h5>We'd love your feedback on last week's loaf. What did you think?</h5>
        <div className="row mt-3 mb-5">
          <input className="form-control" type="text" placeholder="Your feedback" onChange={this.handleFeedback.bind(this)} />
        </div>

        <h5>Items</h5>
        <div className="row mt-3 mb-5">
          {items.map(i => <Item key={i.id} {...i} onChange={() => this.handleItemSelected(i.id)} />)}
        </div>

        {!!addons.length && (
          <div>
            <h5>Add-Ons</h5>
            <div className="row mb-5">
              {addons.map(i => <AddOn key={i.id} {...i} onChange={(isSelected) => this.handleAddOnSelected(i.id, isSelected)} />)}
            </div>
          </div>)}

        <h5>Other comments?</h5>
        <div className="row mt-3 mb-5">
          <input className="form-control" type="text" placeholder="Your comments" onChange={this.handleComments.bind(this)} />
        </div>

        <div className="row mt-3 mb-5">
          <button className="form-control" onClick={this.handleCreateOrder.bind(this)}>Submit Order</button>
        </div>
      </div>
    )
  }
}

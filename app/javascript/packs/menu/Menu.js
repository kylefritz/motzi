import React from 'react'

import Item from './Item.js'
import AddOn from './AddOn.js'
import BakersNote from './BakersNote.js'
import User from './User.js'

export default class Menu extends React.Component {
  constructor(props) {
    super(props)
    this.state = { selectedItem: null, addOns: new Set() }
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
  handleCreateOrder() {
    const { selectedItem, addOns, feedback, comments } = this.state;
    if (!selectedItem) {
      alert('Select a bread!')
      return
    }

    const { user } = this.props;
    let order = { feedback, comments, items: [], uid: user.hashid }

    for (const addOn of addOns) {
      order.items.push(addOn)
    }
    this.props.onCreateOrder(order)
  }
  render() {
    const { menu, user } = this.props;
    const { name, bakersNote, items, addons, isCurrent } = menu;

    return (
      <>
        <User user={user} />

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
              disabled={!isCurrent}
              title={isCurrent ? null : "This is not the current menu; you cannot submit an order."}
              className="btn btn-primary btn-lg btn-block" type="button">
              Submit Order
          </button>
          </div>
        </div>
        <User user={user} />
      </>
    )
  }
}

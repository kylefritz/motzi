import React from 'react'

import Item from './Item.js'
import AddOn from './AddOn.js'
import BakersNote from './BakersNote.js'
import User from './User.js'
import BuyCredits from "../buy/App";
import _ from 'lodash'
import Day from './Day';

export default class Menu extends React.Component {
  constructor(props) {
    super(props)
    this.state = { selectedItem: null, addOns: new Set(), day: 'thursday' };
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
  handleDay(day) {
    this.setState({ day })
  }
  handleCreateOrder() {
    const { selectedItem, addOns, feedback, comments, day } = this.state;
    if (_.isNil(selectedItem)) {
      alert('Select a bread!')
      return
    }

    const { user } = this.props;
    let order = { feedback, comments, items: [], uid: user.hashid, day }

    order.items.push(selectedItem)

    for (const addOn of addOns) {
      order.items.push(addOn)
    }
    this.props.onCreateOrder(order)
  }
  render() {
    const { menu, user, onRefreshUser } = this.props;
    const { name, bakersNote, items, addons, isCurrent } = menu;

    if (user && user.credits < 1) {
      // time to buy credits!
      return (<>
        <User user={user} />
        <BuyCredits onComplete={onRefreshUser} />
      </>)
    }

    return (
      <>
        <User user={user} onRefreshUser={onRefreshUser} />

        {/* if low, show nag to buy credits*/}
        {user && user.credits < 4 && <BuyCredits onComplete={onRefreshUser} />}

        <h2>{name}</h2>

        <BakersNote {...{ bakersNote }} />

        <h5>We'd love your feedback on last week's loaf.</h5>
        <div className="row mt-3 mb-5">
          <div className="col">
            <textarea className="form-control" placeholder="What did you think?" onChange={this.handleFeedback.bind(this)} />
          </div>
        </div>

        <h5>Pickup day</h5>
        <div className="row mt-3">
          <Day
            name="thursday"
            description="5pm-7pm"
            checked
            onChange={this.handleDay.bind(this)}
          />
          <Day
            name="saturday"
            description="noon-7pm"
            onChange={this.handleDay.bind(this)}
          />
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
            <textarea placeholder="Your comments" onChange={this.handleComments.bind(this)}
              className="form-control" />
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
        <User user={user} onRefreshUser={onRefreshUser} />
      </>
    );
  }
}

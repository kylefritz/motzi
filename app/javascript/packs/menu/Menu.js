import React from 'react'
import axios from 'axios'

import Item from './Item.js'
import BakersNote from './BakersNote.js'

export default class Menu extends React.Component {
  constructor(props) {
    super(props)
    this.state = { menu: null }
  }
  componentDidMount() {
    axios.get('/menu.json').then(({ data: menu }) => {
      this.setState({ menu })
    }).catch((err) => {
      throw "couldn't get menu"
    })
  }
  handleCreateOrder() {
    const selectedItem = this.state.menu.items[0].id;

    axios.post('/orders.json', {
      feedback: 'this was great',
      comments: 'more cin rolls!',
      items: [selectedItem], // list any addons here too
    }).then(function (response) {
      console.log(response);
    }).catch(function (error) {
      console.log(error);
    });
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
        <h5>Items</h5>
        <div className="row">
          {items.map(i => <Item key={i.id} {...i} />)}
        </div>


        <h5>Add-Ons</h5>
        {addons.map(i => <Item key={i.id} {...i} />)}

        <h5>Place order?</h5>
        <button onClick={this.handleCreateOrder.bind(this)}>Create Order</button>
      </div>
    )
  }
}

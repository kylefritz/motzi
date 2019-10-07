import React from 'react'
import axios from 'axios'

import Item from './Item.js'

export default class PlaceOrder extends React.Component {
  constructor(props) {
    super(props)
    this.state = { menu: null}
  }
  componentDidMount() {
    axios.get('/menu').then(({ data: menu }) => {
      this.setState({ menu })
    }).catch((err) =>{
      throw "couldn't get menu"
    })
  }
  handleCreateOrder() {

    axios.post('/orders', {
      firstName: 'Fred',
      lastName: 'Flintstone'
    }).then(function (response) {
      console.log(response);
    }).catch(function (error) {
      console.log(error);
    });
  }
  render() {
    const {menu} = this.state;
    if(!menu){
      return <div>loading...</div>;
    }
    const { name, bakersNote, items, addons} = menu;

    return (
      <div>
        <h2>{name}</h2>
        <div>{bakersNote}</div>
        <h5>Items</h5>
        {items.map(i => <Item key={i.id} {...i} />)}

        <h5>Add-Ons</h5>
        {addons.map(i => <Item key={i.id} {...i} />)}

        <h5>Place order?</h5>
        <button onClick={this.handleCreateOrder.bind(this)}>Create Order</button>
      </div>
    )
  }
}

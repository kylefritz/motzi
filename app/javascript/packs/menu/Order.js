import React from 'react'

import Item from './Item.js'
import AddOn from './AddOn.js'
import BakersNote from './BakersNote.js'

export default function ({ menu, user, order }) {
  const { name, bakersNote, items, addons } = menu;

  return (
    <>
      <h2>{name} - Order Placed!</h2>
      <p>Order for: {user.name}</p>

      <BakersNote {...{ bakersNote }} />

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
    </>
  )
}
import React from 'react'
import _ from 'lodash'

import BakersNote from './BakersNote.js'

export default function ({ menu, user, order }) {
  const { name, bakersNote, items, addons } = menu;

  //
  // from the order, lookup each item's name
  // then sort the items by name and aggregate the count of items
  //
  const allItems = _.concat(items, addons)
  const orderItemsCounts = _.reduce(order.items, (acc, { itemId }) => {
    if (acc[itemId] == undefined) {
      acc[itemId] = 0
    }
    acc[itemId] += 1
    return acc
  }, {})
  const orderItems = Object.entries(orderItemsCounts)
  const menuItemLookup = _.keyBy(allItems, i => i.id)
  const lookupMenuItem = id => _.get(menuItemLookup[id], 'name', id)
  const sortedOrderItems = _.sortBy(orderItems, ([id, count]) => lookupMenuItem(id))

  return (
    <>
      <h2 className="mt-5">We got your order!</h2>

      <div className="row mt-5">
        <div className="col">
          <h5>For</h5>
          <p>{user.name}</p>
        </div>
        <div className="col">
          <h5>Items</h5>
          <ul>
            {sortedOrderItems.map(([id, count], i) => {
              return <li key={i}>
                {count > 1 && <strong className="mr-2">{count}x</strong>}
                {lookupMenuItem(id)}
              </li>
            })
            }
          </ul>
        </div>
      </div>

      <hr className="mb-5" />

      <h2 className="mt-3 mb-5">{name}</h2>
      <BakersNote {...{ bakersNote }} />
    </>
  )
}
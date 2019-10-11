// Run this example by adding <%= javascript_pack_tag 'menu' %> to an erb page

import ErrorBoundary from './menu/ErrorBoundary.js'
import PlaceOrder from './menu/PlaceOrder.js'

import React from 'react'
import ReactDOM from 'react-dom'

document.addEventListener('DOMContentLoaded', () => {
  console.log('from webpack')
  const jsx = (<ErrorBoundary><PlaceOrder /></ErrorBoundary>)
  ReactDOM.render(
    jsx,
    document.getElementById('react-mount-container')
  )
})

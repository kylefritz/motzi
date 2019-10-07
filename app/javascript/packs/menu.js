// Run this example by adding <%= javascript_pack_tag 'menu' %> to an erb page

import ErrorBoundary from './menu/ErrorBoundary.js'
import App from './menu/App.js'

import React from 'react'
import ReactDOM from 'react-dom'

document.addEventListener('DOMContentLoaded', () => {
  console.log('from webpack')
  const jsx = (<ErrorBoundary><App /></ErrorBoundary>)
  ReactDOM.render(
    jsx,
    document.body.appendChild(document.createElement('div')),
  )
})

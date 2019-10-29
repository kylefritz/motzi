// Run this example by adding <%= javascript_pack_tag 'menu' %> to an erb page

import ErrorBoundary from './menu/ErrorBoundary.js'
import Menu from './menu/Menu.js'

import React from 'react'
import ReactDOM from 'react-dom'

document.addEventListener('DOMContentLoaded', () => {
  ReactDOM.render(
    (
      <ErrorBoundary>
        <Menu />
      </ErrorBoundary>
    ),
    document.getElementById('react-menu')
  )
})

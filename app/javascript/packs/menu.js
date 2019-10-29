// Run this example by adding <%= javascript_pack_tag 'menu' %> to an erb page

import ErrorBoundary from './menu/ErrorBoundary.js'
import Container from './menu/Container.js'
import Menu from './menu/Menu.js'

import React from 'react'
import ReactDOM from 'react-dom'

document.addEventListener('DOMContentLoaded', () => {
  ReactDOM.render(
    (
      <Container>
        <ErrorBoundary>
          <Menu />
        </ErrorBoundary>
      </Container>
    ),
    document.getElementById('react-menu')
  )
})

// Run by adding <%= javascript_pack_tag 'credits' %> to an erb page

import ErrorBoundary from './ErrorBoundary.js'
import App from './credits/App.js'

import React from 'react'
import ReactDOM from 'react-dom'

document.addEventListener('DOMContentLoaded', () => {
  ReactDOM.render(
    (
      <ErrorBoundary>
        <App />
      </ErrorBoundary>
    ),
    document.getElementById('react-credits')
  )
})

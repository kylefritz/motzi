// Run this example by adding <%= javascript_pack_tag 'order' %> to an erb page

import {Page} from './order/page.js'

import React from 'react'
import ReactDOM from 'react-dom'

document.addEventListener('DOMContentLoaded', () => {
  console.log('from webpack')
  ReactDOM.render(
    <Page />,
    document.body.appendChild(document.createElement('div')),
  )
})

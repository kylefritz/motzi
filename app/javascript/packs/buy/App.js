import React, { useState } from 'react'
import axios from 'axios'
import * as Sentry from '@sentry/browser'
import _ from 'lodash'

import Choice from './Choice'
import Feedback from './Feedback'
import Payment from './Payment'

export default function Buy() {
  const [choice, setChoice] = useState("weekly")

  const dont = choice == "dont"
  const price = choice == "bi-weekly" ? 94 : 172

  return (
    <>
      <h2>Buy credits</h2>
      <Choice name="Weekly" price={172} onChoose={setChoice} />
      <Choice name="Bi-Weekly" price={94} onChoose={setChoice} />
      <Choice name="I don't want to renew" value="dont" onChoose={setChoice} />
      {dont ? <Feedback /> : <Payment choice={choice} price={price} />}
    </>
  )
}

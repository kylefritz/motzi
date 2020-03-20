import React, { useState } from 'react'
import axios from 'axios'
import * as Sentry from '@sentry/browser'
import _ from 'lodash'

import Choice from './Choice'
import Feedback from './Feedback'
import Payment from './Payment'

const weeklyPrice = 172;
const biweeklyPrice = 94;

export default function Buy() {
  const [choice, setChoice] = useState()

  const dont = choice == "dont"
  const price = choice == "bi-weekly" ? biweeklyPrice : weeklyPrice

  return (
    <div className="alert alert-info" role="alert">
      <h2>Renew your subscription</h2>
      <Choice name="Weekly" price={weeklyPrice} onChoose={setChoice} />
      <Choice name="Bi-Weekly" price={biweeklyPrice} onChoose={setChoice} />
      <Choice name="I don't want to renew" value="dont" onChoose={setChoice} />
      {choice && (dont ? <Feedback /> : <Payment choice={choice} price={price} />)}
    </div>
  );
}

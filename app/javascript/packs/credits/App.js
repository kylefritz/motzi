import React from 'react'
import axios from 'axios'
import * as Sentry from '@sentry/browser'
import _ from 'lodash'

export default class App extends React.Component {
  constructor(props) {
    super(props)
    this.selectRef = React.createRef()
    this.cbRef = React.createRef()
    const userId = _.get(location.pathname.match(/users\/(.*)/), 1)
    this.state = { userId }
  }

  loadMenu() {
    const { userId } = this.state
    axios.get(`/menus/${userId}.json`).then(({ data: { menu, user } }) => {
      this.setState({ menu })
      Sentry.configureScope((scope) => scope.setUser(user))
    }).catch((error) => {
      console.error("cant load menu", error)
      Sentry.captureException(error)
      this.setState({ error: "We can't load the menu" })
    })
  }

  componentDidMount() {
    this.loadMenu()

    axios.get(`/items.json`).then(({ data: { items } }) => {
      this.setState({ items })
    }).catch((error) => {
      console.error("cant load items", error)
      Sentry.captureException(error)
      this.setState({ error: "We can't load the items" })
    })
  }

  render() {

    return (
      <details>
        <summary>Add credit</summary>
        <form>
          <fieldset>
            <ol>
              <li className="string input optional stringish">
                <label htmlFor="credit_entry_memo" className="label">Memo</label>
                <input type="text" name="credit_entry[memo]" />
              </li>

              <li className="number input optional numeric stringish">
                <label htmlFor="credit_entry_quantity" className="label">Quantity</label>
                <input step="any" type="number" name="credit_entry[quantity]" />
              </li>

              <li className="number input optional numeric stringish">
                <label htmlFor="credit_entry_good_for_weeks" className="label">Good for weeks</label>
                <input step="any" type="number" name="credit_entry[good_for_weeks]" />
              </li>
            </ol>
          </fieldset>
          <fieldset>
            <ol>
              <li className="action input_action " id="credit_entry_submit_action">
                <input type="submit" value="Add credit" />
              </li>
            </ol>
          </fieldset>
        </form >
      </details>
    )
  }
}

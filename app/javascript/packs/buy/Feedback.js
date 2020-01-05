import React, { useState } from 'react'
import _ from 'lodash'

export default function Feedback({ name, price }) {
  const [feedback, setFeedback] = useState(null)

  const handleSubmit = () => {
    console.warn("TODO: wire submit feedback", feedback)
  }
  return <>
    <h5>Give us feedback</h5>
    <div className="row mt-3 mb-5">
      <div className="col">
        <textarea className="form-control" placeholder="Please give us feedback on why you're not renewing"
          onChange={({ target }) => setFeedback(_.trim(target.value))} />
      </div>
    </div>

    <div className="row mt-3 mb-5">
      <div className="col">
        <button onClick={handleSubmit}
          disabled={!feedback}
          title="Thanks for your feedback!"
          className="btn btn-primary btn-lg btn-block" type="button">
          Submit Feedback
        </button>
      </div>
    </div>
  </>
}

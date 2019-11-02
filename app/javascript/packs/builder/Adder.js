import React from 'react'
import _ from 'lodash'

export default function ({ items, not, onAdd }) {
  const selectRef = React.createRef()
  const handleAdd = () => {
    const itemId = selectRef.current.value;
    if (!itemId) {
      alert('Select an item')
      return
    }
    onAdd(itemId)
  }

  const choices = _.sortBy(items, ({ name }) => name).filter(i => !not.has(i.name))
  return (
    <>
      <select ref={selectRef}>
        {choices.map(({ id, name }) => <option key={id} value={id}>{name}</option>)}
      </select>
      {" "}
      <button type="button" onClick={handleAdd}>Add</button>
    </>
  )
}
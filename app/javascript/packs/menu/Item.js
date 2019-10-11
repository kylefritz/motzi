import React from 'react'

export default class Item extends React.Component {
  render() {
    const { name, description, image } = this.props;

    return (
      <div>
        <h6>{name}</h6>
        <div>{description}</div>
        <img src={image} height={300} width={300} style={{ objectFit: 'contain' }} />
      </div>
    )
  }
}

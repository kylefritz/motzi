import React from 'react'

export default class Item extends React.Component {
  render() {
    const { name, description, image } = this.props;

    return (
      <div className="col-6">
        <h6>{name}</h6>
        <div>{description}</div>
        <img src={image} height={195} width={260} style={{ objectFit: 'contain' }} />
      </div>
    )
  }
}

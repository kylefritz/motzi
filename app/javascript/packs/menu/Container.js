import React from 'react'

export default function Container({ children }) {
  return (
    <div class="background">
      <div class="banner-container">
        <div class="banner" />
      </div>
      <div class="container">
        <h1>Motzi Bread</h1>
        {children}
      </div>
    </div>
  );
}

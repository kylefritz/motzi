import React from 'react'
import { Converter } from 'showdown'

export default function ({ bakersNote }) {
  const converter = new Converter()
  const noteHtml = converter.makeHtml(bakersNote)
  return (
    <div className="bakers-note" dangerouslySetInnerHTML={{ __html: noteHtml }} />
  );
}

import React from "react";
import { Converter } from "showdown";

export default function ({ bakersNote }) {
  const converter = new Converter({
    encodeEmails: false, // adds uncessary obfuscation to email addresses
    excludeTrailingPunctuationFromURLs: true,
    headerLevelStart: 3,
    simpleLineBreaks: true,
    simplifiedAutoLink: true,
  });
  const noteHtml = converter.makeHtml(bakersNote);
  return (
    <div
      className="bakers-note"
      dangerouslySetInnerHTML={{ __html: noteHtml }}
    />
  );
}

// Load all the channels within this directory and all subdirectories.
// Channel files must be named *_channel.(t|j)sx?

const channels = require.context(".", true, /_channel\.(t|j)sx?$/);
channels.keys().forEach(channels);

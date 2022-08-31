# Site

This is the source code for [stefanovazzoler.com](https://stefanovazzoler.com).

## Quick Start

### Requirements

Before starting, you need [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) installed. Optionally, have `python3` installed.

If you have `flatpak` installed on your `linux` system, run `make setup` as root.
Otherwise run `npm install -g csso-cli` and [install Zola](https://www.getzola.org/documentation/getting-started/installation/).

The makefile assumes that you've installed Zola via flatpak (with `make setup`) - if that's not the case it won't work for you.

### Development

To run a server updating live use `make dev` - this is the best way to do development.

You can also build an optimized dev version of the site with `make build_dev` which will also start a http server with `python3` for you to view the site.

### Build / Deploy

Build the site with `make build`, copy all entries on the `public` folder to the root of your web server.

Note that this builds the website links to point to `https://stefanovazzoler.com`, modify `config.toml` or the `Makefile` to change this.
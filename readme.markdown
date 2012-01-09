# Overview
nox_vcr lets you run VCR outside of your application. It is a Sinatra application that lets you insert and inject VCR cassettes. You can then use it as a proxy for http requests that you want VCR to handle (e.g. record or replay). We did this because:

* We already had a mechanism (nox-ruby) to hijack http request and send them to a proxy (nox)
* We make http requests from within our Rails application and from background jobs (resque)

Nox is something from a TV show apparently. Ask https://github.com/keithpitt.

# Installation and configuration
* Clone the repository to your computer somewhere
* In app.rb, set ```cassette_library_dir``` to point to the root of where you keep your VCR cassettes

# Usage
* Run ```rackup```
* Visit localhost:9292/vcr
* Select a cassette you want to insert. A cassettes will stay inserted across requests until you change or eject it.
* When you want to make an http request that will be handled by VCR, set your 'real' request url in the ```NOX_URL``` header
* Make your http request to localhost:9292/request

# Credits
* Much of the VCR-handling code came from https://github.com/unixcharles/vcr-remote-controller. I recommend you look at or use this if you want to run VCR inside your application.
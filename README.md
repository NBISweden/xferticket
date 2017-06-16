# xferticket -- transient storage

Create transient storage areas with public but hard-to-guess links. Links and
content are deleted after a predefined expiry time.


Authentication is required to create new xfertickets. Currently, ldap
authentication is supported, but there is also a simple password option for
testing the software.


Once an xferticket is created, files can be up- and downloaded using a web
browser or a command line tool like [curl](https://curl.haxx.se/).


## Configuration

Application settings are done in <tt>conf/config.yml</tt>, see
<tt>conf/config-example.yml</tt> for an example.


For conserving sessions when the application is restarted, use the environment
variable <tt>SESSION_SECRET</tt>. If undefined, a new session secret is
automatically generated.


## Starting xferticket

    bundle install
    bundle exec foreman start

## Deployment

See INSTALL for deployment instructions. (TBC)

## Acknowledgments

This project was inspired by other well-written file sharing utilities, e.g.
[goploader]() and [Coquelicot](https://coquelicot.potager.org/)

(c) 2017 Mikael Borg. This code is distributed under the GPLv3 license.


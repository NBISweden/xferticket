# xferticket -- transient storage

![](./lib/xferticket/public/xferticket.svg)

Create transient storage areas with public but hard-to-guess links. Links and
content are deleted after a predefined expiry time.

Authentication is required to create new xfertickets. Currently, ldap
authentication is supported, but there is also a simple password option for
testing the software.

Once a xferticket is created, files can be up- and downloaded using a web
browser or a command line tool like [curl](https://curl.haxx.se/).

## Configuration

Application settings are done with a YAML-file, `conf/config.yml`, see
`conf/config-example.yml` for an example.

For conserving sessions when the application is restarted, use the environment
variable `SESSION_SECRET`. If undefined, a new session secret is
automatically generated.

## Starting xferticket

Install ruby and some libraries:

```bash
    sudo apt-get install ruby libldap2-dev libsasl2-dev libsqlite3-dev
```

Install required ruby libraries:

```bash
    bundle install
```

Make a configuration file

```bash
    cp config/config-example.yml config/config.yml
```

Create a directory where xferticket is storing files:

```bash
    mkdir /tmp/xferticket
```

Start local server:

```bash
    bundle exec foreman start
```

Now you can test xferticket by pointing your browser to [http://localhost:5000](http://localhost:5000/).

## Run in docker (non-persistent, suitable for development)

```bash
cp config/config-example.yml config/config.yml
mkdir -p tmp/{log,sockets}
docker build . -t xferticket
docker run --rm -d -v "$PWD/config:/usr/src/app/config" -p 5000:5000 xferticket
```

## In docker with persistent data

Some paths are meant to be replaced, these are in CAPITAL LETTERS.

When editing the configuration, point `datadir` to where you map the
data storage. You also need to ensure the user that the web server
runs as has permissions to write in that location.

Prepare the configuration (you can use `config/config-example.yml` to
see available options) and make it available at `LOCAL_PATH_TO_CONFIGFILE`.

```bash
mkdir -p tmp/{log,sockets}
docker build . -t xferticket
docker run --rm -d -e CONFIGFILE=/SOME/PATHINCONTAINER \
  -v LOCAL_PATH_TO_CONFIGFILE:/SOME/PATHINCONTAINER \
  -v "LOCAL_PATH_TO_DATA:/DATAPATH/INCONTAINER" \
  -p 5000:5000 xferticket
```

## Typical use case

A typical use case could be 

```bash
docker run --rm -d -e CONFIGFILE=/data/config.yml \
  -v "LOCAL_PATH_TO_DATA:/data" \
  -p 5000:5000 xferticket
```

where the `config.yml` file is kept in the data area (and
`LOCAL_PATH_TO_DATA` is writable for at least the user that needs to
for the container to operate).

## Deployment

See INSTALL for deployment instructions. (TBC)

## Acknowledgments

This project was inspired by other well-written file sharing utilities, e.g.
[goploader](https://up.depado.eu/) and [Coquelicot](https://coquelicot.potager.org/)

(c) 2017 Mikael Borg. This code is distributed under the GPLv3 license.


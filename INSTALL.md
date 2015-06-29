# Watchr install

## Preparing the server

### Updating the system

First of all, we need to update the system:

> sudo apt-get update
> sudo apt-get dist-upgrade
> sudo reboot

### Installing Ruby

We need to install an updated version of Ruby, but this requires some dependencies we have to install:

> sudo apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev tcl8.5

Now, we will download the source code of Ruby 2.2.2 and compile it:

> cd /usr/local/src/
> sudo wget http://ftp.ruby-lang.org/pub/ruby/2.2/ruby-2.2.2.tar.gz
> sudo tar -xzvf ruby-2.2.2.tar.gz
> sudo ./configure --disable-install-rdoc
> sudo make
> sudo make install

Next step is to configure `gem` utility to avoid installing documentations and install some required gems.
> sudo echo "gem: --no-ri --no-rdoc" > ~/.gemrc
> sudo gem install bundler

### Installing MongoDB

First of all, configure official MongoDB APT repository:

> sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
> echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list

Next, install and start the latest version of MongoDB:

> sudo apt-get update
> sudo apt-get install -y mongodb-org
> sudo service mongod start

### Installing Redis

We are going to install latest version of Redis from source:

> cd /usr/local/src
> sudo wget http://download.redis.io/releases/redis-3.0.1.tar.gz
> sudo tar -xzvf redis-3.0.1.tar.gz
> cd redis-3.0.1
> sudo make
> sudo make test

If all test are OK, we can continue:

> sudo make install
> cd utils
> sudo ./install_server.sh

For this tutorial, you have to select all the default values suggested by the installer, just pressing ENTER every time. After that, Redis will be installed and we only have to add it to the startup services list and start the server:

> sudo update-rc.d redis_6379 defaults
> sudo service redis_6379 start

### Installing Java

Java is required to do the deploys (YUI is used to compress the assets), so we need to install it:

> sudo apt-add-repository ppa:webupd8team/java
> sudo apt-get update
> sudo apt-get install oracle-java8-installer

### Preparing the environment

We have to create a user for Watchr:

> sudo adduser watchr

Set a complex password (that you can remember later) for this user. This user will be used to make deploys and to run the software itself. Also, you should add the user to the sudoers group:

> sudo usermod -a -G sudo watchr

And prepare the folder in which we are going to store Watchr's files:

> sudo mkdir /srv/watchr
> sudo chown watchr:watchr /srv/watchr

## Preparing the deploy

To prepare the deploy, copy the file from `config/deploy/production.default.rb` to `config/deploy/production.rb` and modify it to set your server's IP address/domain, the user (in this case, `watchr`) and the password you set previously for that user. Also, you should modify the file path which you have created previously.

Also, you should copy the file `config/watchr.default.yml` to `config/watchr.yml` and edit it to set your configuration under `production` tag. Please, note that you must take special care with unicorn configuration, because it should match the user and directories configuration made in this tutorial.

It is also important to configure correctly all the parameters, because MongoDB and Redis are needed to work, and the e-mail server configuration is needed to send the password by e-mail during the web installation and when you create users.

Now, do the first deploy:

> cap production deploy

If everything is correct, the deploy should complete fine. If something fails, may be there are some misconfigured permissions or inexistent folders, you should check everything.

If the process got freezed at the end doing some `sudo` operation, you should set the `sudo` configuration to enable executing sudo commands without password on `watchr` user.

## Installing and configuring NGiNX

First of all, install NGiNX:

> sudo apt-get install nginx

Now, we need to configure NGiNX. Following this tutorial, the configuration under `/etc/nginc/sites-available/watchr` could be:

```
upstream watchr_unicorn {
    server unix:/srv/watchr/shared/unicorn.socket fail_timeout=0;
}

server {
    listen       80;
    server_name your.watchr.domain;

    root /srv/watchr/current/public;

    try_files $uri /;

    location / {
        #all requests are sent to the UNIX socket
        proxy_pass  http://watchr_unicorn;
        proxy_redirect     off;

        proxy_set_header   Host             $host;
        proxy_set_header   X-Real-IP        $remote_addr;
        proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;

        client_max_body_size       10m;
        client_body_buffer_size    128k;

        proxy_send_timeout         90;
        proxy_read_timeout         90;

        proxy_buffer_size          4k;
        proxy_buffers              4 32k;
        proxy_busy_buffers_size    64k;
        proxy_temp_file_write_size 64k;
    }

    location ~ ^/(images|javascripts|stylesheets|system|assets)/  {
        root /srv/watchr/current/public;
        gzip_static on;
        access_log off;
        expires max;
        add_header Cache-Control public;
        break;
    }

    location ~* \.(ico|html|html|txt|png)$ {
        root /srv/watchr/current/public;
        gzip_static on;
        access_log off;
        expires max;
        add_header Cache-Control public;
        break;
    }
}
```

Then, you should apply this configuration and restart the server:

> sudo ln -s /etc/nginx/sites-available/watchr /etc/nginx/sites-enabled/watchr
> sudo rm /etc/nginx/sites-enabled/default
> sudo service nginx stop
> sudo service nginx start

Now, you can access the application using your web browser!

## Aditional recommendations

* You should check the firewall so MongoDB and Redis won't be accesible from the Internet.
* You should use certificate login only in your SSH session, because `watchr` user has a lot of privileges.
* Some probes require to run Watchr as `root` user, and you can do it changing everything from `watchr` to `root` user.

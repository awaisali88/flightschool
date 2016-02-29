# Installing Project FlightSchool on Debian/Ubuntu System #

Below are instructions for setting up Rails+Postgres on Ubuntu 5.10.  Setting up on debian should not be much different - you
can use following two articles as reference.

http://www.ubuntuforums.org/showthread.php?t=169891
http://www.debian-administration.org/articles/329

After installing the dependencies, you will need to checkout the code from repository and initialize the db.

Edit the db/migrate/001\_init.rb file to suit your needs, and then run "rake migrate" to complete initialization.

## Postgres ##
```
  sudo su
  apt-get install build-essential
  apt-get install postgresql-common postgresql-8.1   postgresql-
  client-8.1    postgresql-doc-8.1     libpq4     libpq-dev
  postgresql-server-dev-8.1
  apt-get install postgresql-contrib-8.1
```
```
  emacs /etc/postgresql/8.1/main/pg_hba.conf
```
Replace the file with following line:
```
  local   all         all                               trust
```
```
  /etc/init.d/postgresql-8.1 restart
```
## Rails ##
```
  cd /tmp
  wget http://rubyforge.org/frs/download.php/7858/ruby-1.8.4.tar.gz
  tar -xvzf ruby-1.8.4.tar.gz
  cd ruby-1.8.4
  ./configure
  emacs ext/Setup
  remove # in front of readline and zlib
  make
  make install
```
```
  apt-get install libncurses5-dev libreadline5-dev
  cd ext/readline
  ruby extconf.rb
  make
  sudo make install
```
```
  apt-get install zlib1g
  apt-get install zlib1g-dev
  apt-get install libzlib-ruby
```
```
  cd /tmp
  wget http://www.blue.sky.or.jp/atelier/ruby/ruby-zlib-0.6.0.tar.gz
  tar -xvzf ruby-zlib-0.6.0.tar.gz
  cd ruby-zlib-0.6.0
  ruby extconf.rb
  make install
```
```
  cd /tmp
  wget http://rubyforge.org/frs/download.php/5207/rubygems-0.8.11.tgz
  tar -xvf rubygems-0.8.11.tgz
  cd rubygems-0.8.11
  ruby setup.rb
```
```
  gem install rails --include-dependencies
  gem install ruby-postgres
```
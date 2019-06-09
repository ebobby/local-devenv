#!/bin/bash

################################################################################
# Some basic setup for the provision to run
################################################################################
/usr/sbin/update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
export DEBIAN_FRONTEND=noninteractive

apt-get -y update
apt-get -y install gnupg2 git software-properties-common unattended-upgrades psmisc \
        nano lsb-release man-db

################################################################################
# Add custom repositories
################################################################################
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Multiverse
apt-add-repository multiverse                                                                                                # Multiverse
# PostgreSQL repositories
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' # PostgreSQL repositories
# Neofetch
add-apt-repository ppa:dawidd0811/neofetch

# Sane update/upgrade.
apt-get -y update
apt-get -y upgrade

################################################################################
# Install basic requirements and utilities
################################################################################
apt-get -y install build-essential curl gdb git htop imagemagick linux-tools-generic openssl \
        rar rlwrap screen silversearcher-ag subversion systemtap tree unrar \
        unzip valgrind vim zip zsh unattended-upgrades psmisc nano

################################################################################
# Ruby/Rails requirements
################################################################################
apt-get -y install zlib1g-dev libssl-dev libreadline-dev libyaml-dev libsqlite3-dev \
        sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev libffi-dev

################################################################################
# Neofetch
################################################################################
apt-get install neofetch

################################################################################
# Function to run rbenv commands
################################################################################
execute_with_rbenv () {
    `cat >/home/vagrant/temp-script.sh <<\EOF
export HOME=/home/vagrant
if [ -d $HOME/.rbenv ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
fi

EOF
`
    echo $1 >> /home/vagrant/temp-script.sh
    chmod +x /home/vagrant/temp-script.sh
    su vagrant -c "bash -c /home/vagrant/temp-script.sh"
    rm /home/vagrant/temp-script.sh
}

install_ruby_and_bundler () {
    execute_with_rbenv "MAKE_OPTS='-j6' rbenv install $1"
    execute_with_rbenv "rbenv local $1"
    execute_with_rbenv "gem install bundler"
}

################################################################################
# Install rbenv
################################################################################
`cat >/home/vagrant/install_rbenv.sh <<\EOF
git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
EOF
`
chmod +x /home/vagrant/install_rbenv.sh
su vagrant -c "bash -c /home/vagrant/install_rbenv.sh"
rm /home/vagrant/install_rbenv.sh

################################################################################
# Function to run nvm commands
################################################################################
execute_with_nvm () {
    `cat >/home/vagrant/temp-script.sh <<\EOF
export HOME="/home/vagrant"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

EOF
`
    echo $1 >> /home/vagrant/temp-script.sh
    chmod +x /home/vagrant/temp-script.sh
    su vagrant -c "bash -c /home/vagrant/temp-script.sh"
    rm /home/vagrant/temp-script.sh
}

################################################################################
# Install nvm
################################################################################
`cat >/home/vagrant/install_nvm.sh <<\EOF
git clone https://github.com/creationix/nvm.git ~/.nvm
cd ~/.nvm
git checkout $(git describe --abbrev=0 --tags)
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bash_profile
echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> ~/.bash_profile
EOF
`
chmod +x /home/vagrant/install_nvm.sh
su vagrant -c "bash -c /home/vagrant/install_nvm.sh"
rm /home/vagrant/install_nvm.sh

################################################################################
# Install the Rubies
################################################################################
RUBIES=(
    2.6.3
)

for i in "${RUBIES[@]}"
do
    install_ruby_and_bundler "$i"
done
execute_with_rbenv "rbenv global ${RUBIES[-1]}"

################################################################################
# Install NodeJS
################################################################################
execute_with_nvm "nvm install lts/dubnium"
execute_with_nvm "nvm alias default lts/dubnium"
execute_with_nvm "nvm use default"
execute_with_nvm "npm -g install npm@latest"

################################################################################
# Install PostgreSQL 10
################################################################################
apt-get -y install postgresql-10 postgresql-contrib-10 postgresql-client-10
apt-get -y install libpq-dev

sudo -u postgres pg_dropcluster --stop 10 main
sudo -u postgres pg_createcluster --start 10 main
sudo -u postgres createuser -d -R -w -s vagrant -p 5432
perl -i -p -e 's/local   all             all                                     peer/local all all trust/' /etc/postgresql/10/main/pg_hba.conf

################################################################################
# Basic environment setup
################################################################################
echo "local.dev" > /etc/hostname
echo "127.0.0.1 devenv" >> /etc/hosts
echo '127.0.0.1 local.dev' >> /etc/hosts
hostname local.dev

`cat >/home/vagrant/.environment.sh <<\EOF
# Environment variables
eval "$(dircolors)"
export PS1="[\[\033[1;35m\]\u\[\033[0m\]@\[\033[1;34m\]\h\[\033[0m\]:\[\033[1;37m\]\w\[\033[0m\]]$ "
export DISPLAY=:99
export TERM=xterm-256color

alias ls="ls --color=auto"
alias grep="grep --color=auto"
alias egrep="egrep --color=auto"
alias fgrep="fgrep --color=auto"
alias glog='git log --oneline --decorate --graph'
alias careful="cd /vagrant/careful"
alias careflow="cd /vagrant/careflow"
alias mmaker="cd /vagrant/money_maker"

# Load secret keys, if any.
if [ -f ~/.secret_keys.sh ]; then
  source ~/.secret_keys.sh
fi

neofetch

EOF
`
echo 'source ~/.environment.sh' >> /home/vagrant/.bash_profile
touch /home/vagrant/.secret_keys.sh
chown vagrant:vagrant /home/vagrant/.environment.sh
chown vagrant:vagrant /home/vagrant/.secret_keys.sh

################################################################################
# Configuration
################################################################################
`cat >/home/vagrant/.ssh/config <<\EOF
Host *
  ForwardAgent yes
EOF
`

`cat >/home/vagrant/.gitconfig <<\EOF
[user]
        name = <your-name>
        email = <your-email>
[push]
	default = simple
EOF
`
chown vagrant:vagrant /home/vagrant/.ssh/config
chown vagrant:vagrant /home/vagrant/.gitconfig

################################################################################
# And some basic cleanup
################################################################################
apt-get -y autoremove
apt-get -y autoclean
apt-get -y clean

echo "#####################################################################################"
echo "# Welcome to the Local unofficial development environment!                           "
echo "#                                                                                    "
echo "# You are not yet done! You need to do the following to finish the setup:            "
echo "# 1) Get all the project repositories                                                "
echo "# 2) Configure your ssh username and git information:                                "
echo "#     nano ~/.ssh/config                                                             "
echo "#     nano ~/.gitconfig                                                              "
echo "#                                                                                    "
echo "#####################################################################################"

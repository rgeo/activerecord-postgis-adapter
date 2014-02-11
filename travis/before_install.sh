echo "yes" | sudo apt-add-repository ppa:ubuntugis/ubuntugis-unstable

sudo apt-get update
sudo apt-get install -qq libgeos-dev libproj-dev postgresql-9.1-postgis
sudo apt-get install -qq libgeos++-dev


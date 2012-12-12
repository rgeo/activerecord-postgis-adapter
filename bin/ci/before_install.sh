if [[ "$POSTGIS" == "2.0" ]]; then
  echo "yes" | sudo apt-add-repository ppa:ubuntugis/ubuntugis-unstable
fi

sudo apt-get update
sudo apt-get install -qq libgeos-dev libproj-dev postgresql-9.1-postgis

if [[ "$POSTGIS" == "2.0" ]]; then
  sudo apt-get install -qq libgeos++-dev
fi

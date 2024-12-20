#!/bin/bash

# WARNING: This script is intended to be executed by `./create.bash`

#####################
### INIT Symbiose ###
#####################

docker exec "$USERNAME" bash -c "
mv packages packages-core
yes | git clone -b dev-2.0 https://github.com/yesbabylon/symbiose.git packages
mv packages-core/{core,demo} packages/
rm -rf packages-core
./equal.run --do=init_package package=inventory --import=true --import_cascade=true --force=true
"

printf "Clone and setup of Symbiose finished.\n"

exit 0

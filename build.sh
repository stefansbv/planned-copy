#!/bin/bash

dzil build

# Get the name of the dist
for dir in $( find $directory -type d -name 'App-PlannedCopy-*' | sort )
do
    dir_name=$(basename $dir)
    echo "# $dir_name"
done

cd $dir_name

pp -I lib \
   --output=bin/plcp \
   --compress 6 \
   -M='MooseX::App::Plugin::**' \
   -M='MooseX::App::**' \
   -M='Pod::Elemental::' \
   -M='MooseX::Enumeration::' \
   -M 'MooseX::Iterator::' \
   -M='App::PlannedCopy::' \
   --bundle bin/plcp.pl

cp bin/plcp ..

cd ..

dzil clean

echo done.

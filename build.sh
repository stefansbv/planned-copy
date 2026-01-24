#!/bin/bash

dzil build

cd App-PlannedCopy-0.926/

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

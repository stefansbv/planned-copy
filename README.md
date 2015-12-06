Planned Copy
============
Ștefan Suciu
2015-12-06

Version: 0.800

Planned Copy - a smarter copy application for your Linux box.


Description
-----------

This is my solution for the task of managing configuration files,
scripts and other files that need to be copied around.

The idea behind the application is simple, but the implementation is
complicated... :)

I keep my configuration files, like many others do, in a Git
repository.  The task is to install this files to the places where
they belong to, as automated as possible.

A minimal Git repository in `/home/user/configs` looks like this:

```
.
├── emacs
│   ├── custom.el
│   ├── init.el
│   └── resource.yml
├── kde
│   ├── Shell.profile
│   └── resource.yml
├── linux
│   ├── ackrc
│   ├── bash_alias
│   ├── bash_profile
│   ├── bash_prompt
│   ├── bashrc
│   └── resource.yml
└── system
    ├── rc.firebird
    ├── rc.postgresql
    └── resource.yml
```

My solution is to use a
configuration file `resource.yml` in each project directory with the
following information:

An item in the `resource.yml` file:

```YAML
---
resources:
  -
    destination:
      name: .ackrc
      path: '~/'
      perm: 0644
    source:
      name: ackrc
      path: linux
```

The `plcp install linux` command will copy and rename the
`linux/ackrc` file to `/home/user/.ackrc` and will set the permissions
to `0644`.

The `resource.yml` configuration file is automatically
generated/updated by the `plcp resu linux` command, but the
destination path is initially undefined and have to be edited manually
for every record.


Features
--------

The features and also the commands of the application are:

The main commands:
* install - Install the configuration files (copy files and set permissions);
* sync    - Synchronize the configuration files (copy back to the repo);
* check   - Compare the repository files with the installed versions;

Additional helper and info commands:
* config  - Configure the application;
* repo    - Manage the repository (clone only for now);
* resu    - Manage the resource config files (create/update);
* diff    - Run a diff utility on the repo files and the installed versions;
* list    - Print a list of the projects in the repository;
* version - Print the current version;


Quick Usage
-----------

The initial configuration of `plcp`:

```
% plcp config set --url user@host:/path/to/git-repos/configs.git
% plcp config set --path /home/user/configs
```

Clone the repository to localhost:

```
% plcp repo clone
```

Add/update the `resource.yml` file in the `linux` directory:

```
% plcp resu linux
```

Edit the `linux/resource.yml` file and set the destination path for
all the items.

Finally install the files with:

```
% plcp install linux
```

License And Copyright
---------------------

Copyright (C) 2015 Ștefan Suciu

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

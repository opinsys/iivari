Iivari server
=============

Iivari is a digital signage system. It consists of client and server
components - this is the server, a Ruby on Rails (v3) application.

See the [installation instructions in the wiki](/opinsys/iivari/wiki/Server-installation-instructions)

**THIS BRANCH CONTAINS A STANDALONE VERSION WITH OPTIONAL PUAVO INTEGRATION**

Checkout from the `standalone` branch:

    cd iivari
    git checkout -t origin/standalone

To create the first admin user, you must do it manually from
the Rails console. After following the installation procedure:

    cd iivari/server
    bundle exec rails console
    > User.create :login => "admin", :password => "....."

To change the password:

    > user = User.find_by_login "admin"
    > user.password = "new password"
    > user.save

To have transition effects between slides, merge in the experimental `develop+superslides` branch. Slide timers do not work yet.

    cd iivari
    git branch --track superslides origin/develop+superslides
    git merge superslides


Copyright
=========

Copyright © 2010-2012 Opinsys Oy

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.


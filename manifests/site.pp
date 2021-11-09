## site.pp ##
File { backup => false }

node default {
  include profile::base
}

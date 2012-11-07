# Allows execution of commands when irssi's screen instance is attached and detached.
#
# Usage:
#  /set screencmd_attach <command>[; <command2>][; <commandN>]
#  /set screencmd_detach <command>[; <command2>][; <commandN>]
#    The command(s) to execute when screen is attached and detached.
#
#    Example: /set screencmd_attach /echo hello; /echo world!
#

use Irssi;
use strict;

use vars qw($VERSION %IRSSI);
$VERSION = '1.0.0';
%IRSSI = (
    authors     => 'Birunthan Mohanathas',
    contact     => 'firstname@lastname.com',
    name        => 'screencmd',
    description => 'executes commands when screen is attached and detached.',
    license     => 'MIT',
    url         => 'http://poiru.net',
);

my $screen_socket = get_screen_socket();
if (!$screen_socket) {
  Irssi::print('Not running in screen');
  return;
}

Irssi::settings_add_str('misc', 'screencmd_attach', '');
Irssi::settings_add_str('misc', 'screencmd_detach', '');

# TODO: Add adjustable timeout.
Irssi::timeout_add(5000, 'check_status', '');

my $last_status = 0;

sub check_status {
  if (is_screen_attached($screen_socket)) {
    if ($last_status == 0) {
      $last_status = 1;
      execute_commands(Irssi::settings_get_str('screencmd_attach'));
    }
  } else {
    if ($last_status == 1) {
      $last_status = 0;
      execute_commands(Irssi::settings_get_str('screencmd_detach'));
    }
  }

  return 0;
}

sub execute_commands {
  # TODO: Allow escaping of ';'.
  my @commands = split('; ', @_[0]);
  foreach my $command (@commands) {
    Irssi::command($command);
  }
}

# Based on screen_away.pl by Andreas 'ads' Scherbaum <ads@wars-nicht.de>.
sub get_screen_socket {
  if (defined($ENV{STY})) {
    my $socket = `LC_ALL="C" screen -ls`;
    if ($socket !~ /^No Sockets found/s) {
      my $socket_name = $ENV{'STY'};
      my $socket_path = $socket;
      $socket_path =~ s/^.+\d+ Sockets? in ([^\n]+)\.\n.+$/$1/s;
      if (length($socket_path) != length($socket)) {
        return $socket_path . "/" . $socket_name;
      }
    }
  }
}

sub is_screen_attached {
  my @st = stat(@_[0]);
  if (@st[2] & 00100) {
    # Execute permissions so attached.
    return 1;
  }
}

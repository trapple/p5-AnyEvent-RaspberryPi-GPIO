package AnyEvent::RaspberryPi::GPIO;
use strict;
use warnings;
use utf8;
use Carp;
use IO::File;
use AnyEvent;
use AnyEvent::Filesys::Notify;
use Scope::Guard;
use Data::Dumper;

use Class::Tiny qw/channel direction verbose handle register onchange gc/;

our $GPIO_EXPORT    = '/sys/class/gpio/export';
our $GPIO_UNEXPORT  = '/sys/class/gpio/unexport';
our $GPIO_DIR       = '/sys/class/gpio/gpio%d/';
our $GPIO_DIRECTION = '/sys/class/gpio/gpio%d/direction';
our $GPIO_VALUE     = '/sys/class/gpio/gpio%d/value';

our $VERSION = "0.01";

sub BUILD {
  my ($self, $args) = @_;

  $self->channel   || croak "channel is required.";
  $self->direction || croak "direction is required.";
  $self->onchange && ref $self->onchange ne "CODE" && croak "onchange must be code ref.";

  $self->export();
  $self->init();
  $self->onchange && $self->_onchange();
}

sub export {
  my $self = shift;

  open my $fh, '>', $GPIO_EXPORT || croak $!;
  print STDOUT sprintf("export %s > %s\n", $self->channel, $GPIO_EXPORT) if $self->verbose;
  print $fh $self->channel;
  close $fh;

  open my $fh_direction, '>', sprintf($GPIO_DIRECTION, $self->channel) || croak $1;
  print $fh_direction $self->direction;
  close $fh_direction;
}

sub init {
  my $self = shift;
  my $fh;
  if ($self->direction eq "out") {
    open $fh, '+>', sprintf($GPIO_VALUE, $self->channel) || croak $!;
    $fh->autoflush(1);
  } elsif ($self->direction eq "in") {
    open $fh, '<', sprintf($GPIO_VALUE, $self->channel) || croak $!;
  }
  $self->handle($fh);
}

sub _onchange {
  my $self = shift;

  my $watcher = AnyEvent::Filesys::Notify->new({
      dirs     => [sprintf($GPIO_DIR, $self->channel)],
      interval => 0.02,
      filter   => qr/value$/,
      cb       => sub {
        my (@events) = @_;
        for my $event (@events) {
          if ($event->type() eq "modified") {
            $self->onchange->($self->value);
          }
        }
      }
    });
  $self->register($watcher);
}

sub set {
  my $self = shift;
  my $val  = shift;
  croak "set value is required." unless defined $val;

  print STDOUT "set value = $val\n" if $self->verbose;
  seek $self->handle, 0, 0;
  print {$self->handle} $val;
  seek $self->handle, 0, 0;
}

sub value {
  my $self = shift;
  seek $self->handle, 0, 0;
  my $fh = $self->handle;
  chomp(my $val = <$fh>);
  seek $self->handle, 0, 0;
  return $val;
}

sub unexport {
  my $self = shift;
  open my $fh, '>', $GPIO_UNEXPORT || croak $!;
  print STDOUT sprintf("unexport %s > %s\n", $self->channel, $GPIO_UNEXPORT) if $self->verbose;
  print $fh $self->channel;
  close $fh;
}

1;

__END__

=encoding utf-8

=head1 NAME

AnyEvent::RaspberryPi::GPIO - simple async interface for Raspberry Pi GPIO

=head1 SYNOPSIS

    use AnyEvent::RaspberryPi::GPIO;

=head1 DESCRIPTION

RaspberryPi::GPIO is ...

=head1 LICENSE

Copyright (C) trapple.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

trapple E<lt>trapplejp@gmail.comE<gt>

=cut


use strict;
use warnings;
use Test::More;
use Test::Exception;
use AnyEvent::RaspberryPi::GPIO;
use FindBin qw/$Bin/;
use Scope::Guard;
use AnyEvent;

$AnyEvent::RaspberryPi::GPIO::GPIO_EXPORT    = "$Bin/gpio/export";
$AnyEvent::RaspberryPi::GPIO::GPIO_UNEXPORT  = "$Bin/gpio/unexport";
$AnyEvent::RaspberryPi::GPIO::GPIO_DIR       = "$Bin/gpio/gpio17/";
$AnyEvent::RaspberryPi::GPIO::GPIO_DIRECTION = "$Bin/gpio/gpio17/direction";
$AnyEvent::RaspberryPi::GPIO::GPIO_VALUE     = "$Bin/gpio/gpio17/value";

sub read_file {
  my $file = shift;
  open my $fh, '<', $file or die $!;
  my $data = do { local $/; <$fh> };
  return $data;
}

sub write_file {
  my ($file, $val) = @_;
  open my $fh, '>', $file or die $!;
  print $fh $val;
  close($fh);
}

my $setup = sub {
  return Scope::Guard->new(
    sub {
      truncate($AnyEvent::RaspberryPi::GPIO::GPIO_EXPORT,    0);
      truncate($AnyEvent::RaspberryPi::GPIO::GPIO_UNEXPORT,  0);
      truncate($AnyEvent::RaspberryPi::GPIO::GPIO_DIRECTION, 0);
      truncate($AnyEvent::RaspberryPi::GPIO::GPIO_VALUE,     0);
      write_file($AnyEvent::RaspberryPi::GPIO::GPIO_VALUE, 0);
    });
};

subtest "gpio files for testing", sub {
  ok(-f $AnyEvent::RaspberryPi::GPIO::GPIO_EXPORT);
  ok(-f $AnyEvent::RaspberryPi::GPIO::GPIO_UNEXPORT);
  ok(-f $AnyEvent::RaspberryPi::GPIO::GPIO_DIRECTION);
  ok(-f $AnyEvent::RaspberryPi::GPIO::GPIO_VALUE);
};

subtest "new", sub {
  my $gc   = $setup->();
  my $gpio = AnyEvent::RaspberryPi::GPIO->new({
    direction => "out",
    channel   => 17
  });

  is read_file($AnyEvent::RaspberryPi::GPIO::GPIO_EXPORT),    17;
  is read_file($AnyEvent::RaspberryPi::GPIO::GPIO_DIRECTION), "out";
  isa_ok $gpio->handle, "GLOB";
};

subtest "set", sub {
  my $gc   = $setup->();
  my $gpio = AnyEvent::RaspberryPi::GPIO->new({
    direction => "out",
    channel   => 17
  });

  $gpio->set(1);
  is read_file($AnyEvent::RaspberryPi::GPIO::GPIO_VALUE), 1, "read file direct";
  is $gpio->value, 1, "read file from handle";

  $gpio->set(0);
  is read_file($AnyEvent::RaspberryPi::GPIO::GPIO_VALUE), 0, "read file direct";
  is $gpio->value, 0, "read file from handle";

  undef $gpio;

};

subtest "onchange", sub {
  my $gc   = $setup->();
  my $cv = AE::cv;

  $cv->begin;
  my $flag = 0;
  my $gpio = AnyEvent::RaspberryPi::GPIO->new({
    direction => "in",
    channel   => 17,
    onchange => sub {
      my $value = shift;
      $flag = $value;
      $cv->end;
    }
  });

  $cv->begin;
  my $t = AE::timer 2, 0, sub {
    write_file($AnyEvent::RaspberryPi::GPIO::GPIO_VALUE, 1);
    $cv->end;
  };
  $cv->recv;

  is $gpio->value, 1, "read file from handle";
  is $flag, 1;

  undef $gpio;
};

done_testing;


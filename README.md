# NAME

AnyEvent::RaspberryPi::GPIO - simple async interface for Raspberry Pi GPIO

# SYNOPSIS

    use AnyEvent::RaspberryPi::GPIO;

    # gpio out
    my $gpio = AnyEvent::RaspberryPi::GPIO->new({
      direction => "out",
      channel   => 17
    });
    $gpio->set(1);

    #gpio in
    my $cv = AE::cv;
    my $gpio = AnyEvent::RaspberryPi::GPIO->new({
      direction => "in",
      channel   => 17,
      onchange  => sub {
        my $val = shift;
        # do something when value is changed
      }
    });
    $cv->begin;
    my $finalize = AE::signal "INT", sub {
      $cv->end;
    };
    $cv->rcev;

# DESCRIPTION

AnyEvent::RaspberryPi::GPIO is ...

# LICENSE

Copyright (C) trapple.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

trapple <trapplejp@gmail.com>

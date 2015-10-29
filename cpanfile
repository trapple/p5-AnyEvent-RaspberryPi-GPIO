requires 'Class::Tiny', '1.001';
requires 'AnyEvent', '7.11';
requires 'AnyEvent::Filesys::Notify', '1.19';
requires 'Scope::Guard', '0.20';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Exception', '0.40';
};


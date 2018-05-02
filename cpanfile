requires 'perl', '5.014002';

requires 'Mouse';
requires 'Carp';

on 'test' => sub {
    requires 'Test::More', '0.98';
};


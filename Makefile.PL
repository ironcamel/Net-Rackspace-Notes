use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Rackspace::Notes',
    AUTHOR              => 'Naveed Massjouni <naveedm9@gmail.com>',
    VERSION_FROM        => 'lib/Net/Rackspace/Notes.pm',
    ABSTRACT_FROM       => 'lib/Net/Rackspace/Notes.pm',
    LICENSE             => 'perl',
    EXE_FILES           => [ 'script/racknotes' ],
    META_MERGE => {
        resources => {
            repository => 'http://github.com/ironcamel/Net-Rackspace-Notes',
            bugtracker => 'http://github.com/ironcamel/Net-Rackspace-Notes/issues',
        },
    },
    PREREQ_PM => {
        'App::Rad'                               => 0,
        'Config::General'                        => 0,
        'JSON'                                   => 0,
        'LWP::UserAgent'                         => 0,
        'Moose'                                  => 0,
        'Test::More'                             => 0,
        'Term::ReadPassword'                     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Rackspace-Notes-*' },
);

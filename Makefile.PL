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
        'App::Rad'                               => '1.04',
        'JSON'                                   => '2.22',
        'LWP::UserAgent'                         => '5.835',
        'Moose'                                  => '1.12',
        'Parallel::ForkManager'                  => '0.7.6',
        'Term::ReadPassword'                     => '0.11',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Rackspace-Notes-*' },
);

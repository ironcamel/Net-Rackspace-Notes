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
    PL_FILES            => {},
    PREREQ_PM => {
        'Config::General'                        =>  0,
        'JSON'                                   =>  0,
        'LWP::UserAgent'                         =>  0,
        'MooseX::Declare'                        =>  0,
        'MooseX::NonMoose'                       =>  0,
        'Test::More'                             =>  0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Rackspace-Notes-*' },
);

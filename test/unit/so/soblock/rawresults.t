#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../.."; #location of includes.pm
use includes; #file with paths to PsN packages


SKIP: {
    eval { require XML::LibXML };
    skip "XML::LibXML not installed" if $@;

    require so::soblock::rawresults;


    #Empty xml
    my $rr = so::soblock::rawresults->new();
    my $xml = $rr->xml();
    is ($xml, undef, "Empty RawResults");

    #add_datafile
    my $rr = so::soblock::rawresults->new();
    $rr->add_datafile(name => "dir/sdtab28", description => "myDesc");
    is_deeply($rr->DataFile->[0], { Description => 'myDesc', path => 'sdtab28', oid => 'd1' }, "add_datafile");

    $rr->add_datafile(name => "dir/sdtab28", description => 'new');
    is_deeply($rr->DataFile->[0], { Description => 'new', path => 'sdtab28', oid => 'd1' }, "add_datafile again");
    
    my $xml_string = $rr->xml()->toString();
    
    is ($xml_string, '<RawResults><DataFile oid="d1"><ct:Description>new</ct:Description><ds:path>sdtab28</ds:path></DataFile></RawResults>',
        "RawResults"); 
}

done_testing();

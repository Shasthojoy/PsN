#!/etc/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Path 'rmtree';
use FindBin qw($Bin);
use lib "$Bin/../..";
use includes; #file with paths to PsN packages
use data;
use tool::nonparametric;

my $file= $includes::testfiledir."/nonparametric/nonparam_test.csv";

# add npsupp column to the csv file and return an array
my $new_rows = ['"model","problem","subproblem","minimization_successful","ofv","npofv","npsupp","EXP(ETA1)","OMEGA(1,1)"'."\n",
'1,1,1,1,-577.0697682087,-603.46,0,0.00564,0.989'."\n",
'2,1,1,1,-577.0697682087,122.235,100,0.00351,0.991'."\n",
'3,1,1,1,-577.0697682087,1435.2,200,0.00341,0.994'."\n"];

is_deeply(tool::nonparametric::add_column(filename => $file, npsupp => [0,100,200]), $new_rows,'add npsupp column to the data set');

dies_ok {tool::nonparametric::add_column(filename => $file, npsupp => undef)} "undefined parameter npsupp";
dies_ok {tool::nonparametric::add_column(filename => $file, npsupp => [])} "array of the npsupp is empty";
dies_ok {tool::nonparametric::add_column(filename => undef, npsupp => [0,100,200])} "undefined csv file";

done_testing();
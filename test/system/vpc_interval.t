#!/etc/bin/perl

# Blackbox testing of vpc data MDV filtering, formatting to DV matrix and percentile calculation

use strict;
use warnings;
use File::Path 'rmtree';
use Test::More tests=>660;
use FindBin qw($Bin);
use lib "$Bin/.."; #location of includes.pm
use includes; #file with paths to PsN packages and $path variable definition

our $tempdir = create_test_dir('system_vpcinterval');
our $dir = "$tempdir/vpc_test";

my $truematrix=
[[1.7300E+01,1.5591E+01,2.0031E+01,1.3769E+01,1.7572E+01,1.3515E+01,4.1674E+01,2.6360E+01,9.6451E+00,4.4075E+01,1.1120E+01,2.2924E+01,2.9936E+01,1.4643E+01,1.5146E+01,3.2476E+01,2.2444E+01,1.7241E+01,3.6800E+01,2.0314E+01,1.3952E+01],
[3.1000E+01,1.8051E+01,5.3670E+00,2.7881E+01,3.0443E+01,2.0577E+01,3.6862E+01,1.6333E+01,2.0312E+01,5.5049E+01,6.7787E+00,1.7325E+01,2.8790E+01,2.2330E+01,3.4794E+01,1.8869E+01,4.1535E+01,2.5998E+01,4.4654E+01,2.1930E+01,2.3584E+01],
[9.7000E+00,1.0010E+01,6.6823E+00,2.5296E+01,1.1777E+01,8.2582E+00,9.1992E+00,1.0347E+01,9.0354E+00,2.4774E+01,3.6220E+00,2.2194E+01,7.1866E+00,1.2696E+01,1.2647E+01,1.5040E+01,8.5446E+00,1.3799E+01,1.1317E+01,1.1198E+01,9.7341E+00],
[2.4600E+01,1.2944E+01,1.7438E+01,3.5363E+01,1.9665E+01,1.9184E+01,2.0787E+01,2.0402E+01,1.2792E+01,4.3881E+01,6.4175E+00,9.2468E+00,2.0307E+01,1.5785E+01,1.8945E+01,5.5304E+00,3.0660E+01,1.4447E+01,1.3883E+01,1.3475E+01,1.1894E+01],
[3.3000E+01,1.5360E+01,2.8857E+01,4.1573E+01,1.4674E+01,2.1353E+01,1.8643E+01,2.3837E+01,1.3725E+01,2.7978E+01,1.1532E+01,1.1506E+01,2.2681E+01,2.8628E+01,3.1152E+01,7.1955E+00,3.4408E+01,1.2978E+01,2.9378E+01,2.8724E+01,1.6648E+01],
[1.8000E+01,3.1017E+01,2.7790E+01,1.2611E+01,4.2267E+01,6.3467E+01,1.7030E+01,3.1326E+01,1.2408E+01,1.9882E+01,2.8765E+01,4.4509E+01,2.3291E+01,1.7565E+01,7.6072E+01,2.6957E+01,2.4737E+01,1.8135E+01,9.9332E+00,9.5163E+01,4.4484E+01],
[2.3800E+01,7.4396E+01,1.7709E+01,1.8093E+01,3.8484E+01,2.7120E+01,1.3313E+01,2.6869E+01,7.8002E+00,2.0287E+01,3.5437E+01,2.7662E+01,5.1730E+01,1.4850E+01,1.0677E+01,2.5574E+01,1.9568E+01,2.4785E+01,2.2459E+01,3.6731E+01,2.1109E+01],
[2.4300E+01,6.2750E+01,1.5350E+01,1.8438E+01,8.0823E+01,3.9859E+01,2.0170E+01,4.1288E+01,8.5666E+00,2.5166E+01,3.8292E+01,5.1612E+01,4.0940E+01,2.0955E+01,1.5662E+01,1.6456E+01,2.7772E+01,3.0969E+01,2.4303E+01,4.1460E+01,2.5715E+01],
[2.0800E+01,9.5389E+00,1.5338E+01,1.4445E+01,2.5792E+01,1.3253E+01,2.5798E+01,2.7878E+01,1.3829E+01,6.9883E+01,1.2768E+01,3.9048E+01,2.5203E+01,2.0345E+01,2.5140E+01,3.9674E+01,1.0581E+01,1.1960E+01,1.9636E+01,9.6531E+00,1.2260E+01],
[2.3900E+01,1.0886E+01,2.6158E+01,1.8047E+01,9.2489E+00,7.6242E+00,2.1762E+00,9.1342E+00,1.5458E+01,1.4090E+01,6.6809E+00,1.5991E+01,3.8486E+01,1.8745E+01,2.5570E+01,3.5589E+01,8.2638E+00,1.0041E+01,2.1589E+01,1.0408E+01,1.9365E+01],
[3.1700E+01,1.7173E+01,2.1593E+01,1.8365E+01,1.2611E+01,4.2403E+00,2.5694E+00,4.3800E+00,2.0128E+01,1.4207E+01,4.2712E+00,1.4334E+01,3.5601E+01,2.2856E+01,1.7276E+01,4.7450E+01,1.3094E+01,1.0465E+01,1.8011E+01,2.0041E+01,2.2084E+01],
[1.4200E+01,2.8140E+01,3.1147E+01,1.8272E+01,2.7887E+01,1.0598E+01,2.3642E+01,1.9953E+01,1.9108E+01,6.6126E+01,3.2380E+01,5.3485E+01,3.9172E+01,4.9668E+01,4.1326E+01,1.7834E+01,1.6922E+01,1.3200E+01,4.2711E+01,4.0441E+01,1.5312E+01],
[1.8200E+01,3.1659E+01,3.3038E+01,1.1651E+01,1.4606E+01,1.5116E+01,1.4372E+01,1.4196E+01,1.5405E+01,5.0334E+01,1.9695E+01,2.2798E+01,3.8542E+00,1.3561E+01,4.1500E+01,2.2815E+01,1.4941E+01,1.6497E+01,9.7226E+00,3.4961E+01,1.3322E+01],
[2.0300E+01,2.4413E+01,2.6872E+01,1.5122E+01,1.3011E+01,1.5815E+01,1.4066E+01,1.1707E+01,1.3943E+01,5.8246E+01,2.3638E+01,1.3089E+01,2.8958E+00,1.4803E+01,3.3724E+01,2.7012E+01,2.7838E+01,1.2594E+01,8.0155E+00,4.3732E+01,1.4615E+01]
];

my $truematrix2=[
[1.7300E+01,1.5591E+01,2.0031E+01,1.3769E+01,1.7572E+01,1.3515E+01,4.1674E+01,2.6360E+01,9.6451E+00,4.4075E+01,1.1120E+01,1.3899E+01,2.1514E+01,2.2533E+01,2.0084E+01,2.2038E+01,1.7349E+01,2.5027E+01,3.1531E+01,3.1578E+01,2.5118E+01],
[3.1000E+01,1.8051E+01,5.3670E+00,2.7881E+01,3.0443E+01,2.0577E+01,3.6862E+01,1.6333E+01,2.0312E+01,5.5049E+01,6.7787E+00,1.0006E+01,1.8882E+01,1.6194E+01,1.7350E+01,2.7433E+01,9.2635E+00,1.3916E+01,2.0428E+01,4.9428E+01,4.2146E+01],
[9.7000E+00,1.0010E+01,6.6823E+00,2.5296E+01,1.1777E+01,8.2582E+00,9.1992E+00,1.0347E+01,9.0354E+00,2.4774E+01,3.6220E+00,3.3962E+01,2.9559E+01,2.9911E+01,1.8465E+01,6.2909E+00,1.5215E+01,1.6359E+01,1.6886E+01,2.0941E+01,8.6527E+00],
[2.4600E+01,1.2944E+01,1.7438E+01,3.5363E+01,1.9665E+01,1.9184E+01,2.0787E+01,2.0402E+01,1.2792E+01,4.3881E+01,6.4175E+00,3.9448E+01,1.2144E+01,3.6099E+01,1.6116E+01,1.4972E+01,1.3112E+01,2.3557E+01,2.3028E+01,1.0583E+01,1.3805E+01],
[3.3000E+01,1.5360E+01,2.8857E+01,4.1573E+01,1.4674E+01,2.1353E+01,1.8643E+01,2.3837E+01,1.3725E+01,2.7978E+01,1.1532E+01,5.0752E+01,1.2759E+01,3.6621E+01,1.6440E+01,1.5773E+01,1.3628E+01,4.0033E+01,3.9077E+01,1.0762E+01,1.5133E+01],
[1.8000E+01,3.1017E+01,2.7790E+01,1.2611E+01,4.2267E+01,6.3467E+01,1.7030E+01,3.1326E+01,1.2408E+01,1.9882E+01,2.8765E+01,1.1200E+02,3.1900E+01,4.9359E+01,1.5346E+01,3.3162E+01,3.1298E+01,4.8490E+01,7.3855E+00,3.5618E+01,5.8175E+01],
[2.3800E+01,7.4396E+01,1.7709E+01,1.8093E+01,3.8484E+01,2.7120E+01,1.3313E+01,2.6869E+01,7.8002E+00,2.0287E+01,3.5437E+01,6.4604E+01,2.0780E+01,4.1156E+01,1.5906E+01,3.5611E+01,1.7245E+01,4.0555E+01,1.7186E+01,2.7879E+01,6.8927E+00],
[2.4300E+01,6.2750E+01,1.5350E+01,1.8438E+01,8.0823E+01,3.9859E+01,2.0170E+01,4.1288E+01,8.5666E+00,2.5166E+01,3.8292E+01,5.9824E+01,2.3852E+01,4.6315E+01,2.5509E+01,4.0381E+01,2.0280E+01,5.1103E+01,1.9164E+01,3.1417E+01,1.6565E+01],
[2.0800E+01,9.5389E+00,1.5338E+01,1.4445E+01,2.5792E+01,1.3253E+01,2.5798E+01,2.7878E+01,1.3829E+01,6.9883E+01,1.2768E+01,1.3644E+01,4.7723E+01,1.6568E+01,1.2640E+01,1.7799E+01,5.9512E+00,5.5103E+00,2.6614E+01,2.9178E+00,7.5633E+00],
[2.3900E+01,1.0886E+01,2.6158E+01,1.8047E+01,9.2489E+00,7.6242E+00,2.1762E+00,9.1342E+00,1.5458E+01,1.4090E+01,6.6809E+00,9.4671E+00,1.6511E+01,1.2781E+01,1.8967E+01,2.0401E+01,1.0911E+01,1.6673E+01,2.6997E+01,1.1315E+01,1.0724E+01],
[3.1700E+01,1.7173E+01,2.1593E+01,1.8365E+01,1.2611E+01,4.2403E+00,2.5694E+00,4.3800E+00,2.0128E+01,1.4207E+01,4.2712E+00,8.5186E+00,1.2496E+01,1.5518E+01,2.3441E+01,2.3338E+01,8.5443E+00,2.1227E+01,2.3062E+01,1.1816E+01,1.3923E+01],
[1.4200E+01,2.8140E+01,3.1147E+01,1.8272E+01,2.7887E+01,1.0598E+01,2.3642E+01,1.9953E+01,1.9108E+01,6.6126E+01,3.2380E+01,1.7478E+01,2.4749E+01,3.0418E+01,2.5645E+01,1.7743E+01,1.8999E+01,2.0200E+01,1.5307E+01,1.4683E+01,1.3538E+01],
[1.8200E+01,3.1659E+01,3.3038E+01,1.1651E+01,1.4606E+01,1.5116E+01,1.4372E+01,1.4196E+01,1.5405E+01,5.0334E+01,1.9695E+01,1.3459E+01,1.1265E+01,7.2095E+00,2.0924E+01,2.4563E+01,1.4299E+01,2.5868E+01,1.7726E+01,2.2894E+01,1.0456E+01],
[2.0300E+01,2.4413E+01,2.6872E+01,1.5122E+01,1.3011E+01,1.5815E+01,1.4066E+01,1.1707E+01,1.3943E+01,5.8246E+01,2.3638E+01,2.4214E+01,2.8094E+01,5.4178E+00,2.5901E+01,1.9396E+01,1.7343E+01,2.9472E+01,2.7343E+01,2.8689E+01,1.1595E+01]
	];



my $truestats=[
	[18.10000,17.56850,11.94400,43.97800,1.7300E+01,1.3475E+01,6.6809E+00,2.4774E+01,2.0800E+01,2.5140E+01,1.5116E+01,5.0334E+01,1.4200E+01,9.2489E+00,6.4175E+00,1.9882E+01,2.3900E+01,4.1326E+01,1.5458E+01,6.6126E+01],  
	[27.65000,21.23100,13.83400,32.72750,2.4300E+01,1.5815E+01,1.1532E+01,2.8790E+01,3.1700E+01,2.7772E+01,2.0128E+01,6.2750E+01,2.3800E+01,1.0677E+01,6.7787E+00,2.2681E+01,3.3000E+01,4.1460E+01,2.0312E+01,8.0823E+01]
	];

sub get_dv_matrix
{
  open (FILE, "$dir/m1/DV_matrix.csv");
  my @arr = <FILE>;
  close FILE;

  my @matrix=();
  foreach my $line (@arr){
	  chomp $line;
	  my @row = split ',',$line;
	  push(@matrix,\@row);
  }
  return \@matrix;
}
sub is_array{
    my $func=shift;
    my $facit=shift;
    my $label=shift;

    is (scalar(@{$func}),scalar(@{$facit}),"$label, equal length");

    my $min = scalar(@{$func});
    $min = scalar(@{$facit}) if (scalar(@{$facit})< $min);
    for (my $i=0; $i<$min; $i++){
    	cmp_ok ($func->[$i],'==',$facit->[$i],"$label, index $i");
    }		
	
}

sub get_stats
{
  open my $fh, "<", "$dir/vpc_results.csv";

  my @arr = <$fh>;
  close $fh;
  my @ans=();
  my $savenext=0;
  foreach my $line (@arr){
      chomp $line;
	  my $store=0;
      if ($line =~ /first interval is closed/){
		  $store=1;
		  $savenext=1;
      }elsif($savenext){
		  $store=1;
		  $savenext=0;
	  }
	  next unless $store;
	  my @arr = split(/\s*,\s*/,$line);

	  #pick up cells
	  my @newarr = @arr[8 .. 27];
	  #print join(' ',@newarr)."\n\n";
	  push(@ans,\@newarr);
  }
  return \@ans;
}



my $model_dir = $includes::testfiledir;

copy_test_files($tempdir,["pheno5.mod", "pheno5.dta"]);

my $command = $includes::vpc." -samples=20 $tempdir/pheno5.mod -auto_bin=2 -directory=$dir -seed=12345 -min_point=5";
system $command;

my $newmatrix = get_dv_matrix();

is (scalar(@{$newmatrix}),scalar(@{$truematrix}),"DV matrices, equal num rows");
my $num = scalar(@{$newmatrix});

for (my $i = 0; $i < $num; $i++) {
	is_array ($newmatrix->[$i],$truematrix->[$i],"DV matrix row index $i");
}

my $stats = get_stats();
for (my $i = 0; $i < 2; $i++){
	is_array ($stats->[$i],$truestats->[$i],"stats row index $i");
}

rmtree([$dir]);

#split simulation over multiple tabs
$command = $includes::vpc." -samples=20 $tempdir/pheno5.mod -auto_bin=2 -directory=$dir -seed=12345 -min_point=5 -n_sim=2";
system $command;

$newmatrix = get_dv_matrix();

is (scalar(@{$newmatrix}), scalar(@{$truematrix2}), "DV matrices n_sim=2, equal num rows");
$num = scalar(@{$newmatrix});

for (my $i=0; $i< $num; $i++) {
	is_array ($newmatrix->[$i],$truematrix2->[$i],"DV matrix n_sim=2 row index $i");
}

remove_test_dir($tempdir);

done_testing();

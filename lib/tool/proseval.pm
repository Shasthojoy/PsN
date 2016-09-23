package tool::proseval;

use strict;
use Moose;
use MooseX::Params::Validate;
use File::Copy 'cp';
use include_modules;
use data;
use log;
use filter_data;
use tool::modelfit;

extends 'tool';

has 'model' => ( is => 'rw', isa => 'model' ); 
has 'evid_column' => ( is => 'rw', isa => 'Int' ); 
has 'numobs_indiv' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has 'sorted_indiv_numobs' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

sub BUILD
{
    my $self = shift;

	my $model = $self->models()->[0]; 
    my $evid_column = $model->problems->[0]->find_data_column(column_name => 'EVID'); 
    if ($evid_column == -1) {
        die "Error: There is no EVID column in the dataset\n";
    }

    $self->evid_column($evid_column);
    $self->model($model);
}

sub modelfit_setup
{
	my $self = shift;

    filter_data::filter_dataset(model => $self->model);

    #my $orig_data_file = $self->model->datafiles(absolute_path => 1, problem_numbers => [1])->[0];
    my $ignoresign = defined $self->model->ignoresigns ? $self->model->ignoresigns->[0] : '@';

    my $n = 1;
    my $continue = 1;


    $self->model->set_option(record_name => 'estimation', option_name => 'MAXEVALS', fuzzy_match => 1, option_value => '0');
	$self->tools([]) unless defined $self->tools;
    my @models_to_run;

    while ($continue) {
        my $data = data->new(
            filename => "preprocess_data_dir/filtered.dta",
            ignoresign => $ignoresign,
            missing_data_token => $self->missing_data_token,
            idcolumn => $self->model->idcolumn(),
        );

        $continue = $self->set_evid(dataset => $data, numzeros => $n, evid_column => $self->evid_column);

        my $data_filename = "m1/proseval_$n.dta";
        my $model_filename = $self->directory . "m1/proseval_$n.mod";
        $data->_write(filename => $data_filename);

        my $modified_model = $self->model->copy(filename => $model_filename, output_same_directory => 1);
        $modified_model->problems->[0]->datas->[0]->set_filename(filename => $data_filename);

        # Remove all tables
        $modified_model->problems->[0]->tables([]);

		$modified_model->add_records(type => 'table',
            record_strings => ['ID', 'TIME', 'EVID', 'WRES', 'IWRES', 'NOPRINT', 'NOAPPEND', 'ONEHEADER', "FILE=proseval_$n.tab"]);

        $modified_model->_write(filename => $model_filename, relative_data_path => 1);
        push @models_to_run, $modified_model;
        $n++;

        if (not $continue) {
            # Final iteration. Sort numobs before dataset goes out of scope
            for my $individual (@{$data->individuals}) {
                push @{$self->sorted_indiv_numobs}, $self->numobs_indiv->{$individual->idnumber};
            }
        }
    }

	my $modelfit = tool::modelfit->new(
		%{common_options::restore_options(@common_options::tool_options)},
		models => \@models_to_run, 
		base_dir => $self->directory . 'm1/',
		directory => undef,
		top_tool => 0,
        copy_data => 0,
	);

	push(@{$self->tools}, $modelfit);
}

sub modelfit_analyze
{
    # Collect all tables into one results table

    my $self = shift;

    open my $fh, '>', "results.csv";
    print $fh "ID,TIME,EVID,WRES,IWRES,OBS\n";

    for my $ind (0 .. scalar(@{$self->sorted_indiv_numobs}) - 1) {
        for my $numobs (1 .. $self->sorted_indiv_numobs->[$ind]) {
            my $data = data->new(
                filename => "m1/proseval_$numobs.tab",
                missing_data_token => $self->missing_data_token,
                idcolumn => $self->model->idcolumn(),
            );
            my $individual = $data->individuals->[$ind];
            for my $line (@{$individual->subject_data}) {
                print $fh "$line,$numobs\n";
            }
        }
    }

    close $fh;
}

sub set_evid
{
    # Leave the $numzeros first zeros for each individual
    # Change the rest of the zeros to twos
    # Report if no zeros were changed
    my $self = shift;
	my %parm = validated_hash(\@_,
		dataset => { isa => 'data', optional => 0 },
        numzeros => { isa => 'Int', optional => 0 },
        evid_column => { isa => 'Int', optional => 0 },
	);
	my $dataset = $parm{'dataset'};
	my $numzeros = $parm{'numzeros'};
	my $evid_column = $parm{'evid_column'};

    my $set_evid_two = 0;       # Did we set any evid to two?

    for my $individual (@{$dataset->individuals}) {
        my $skipped_zeros = 0;
        my $indiv_set_evid_two = 0;     # Did we set any evid to two for this individual?
        for my $row (@{$individual->subject_data}) {
            my @a = split /,/, $row;
            if ($a[$evid_column] == 0) {
                if ($skipped_zeros < $numzeros) {
                    $skipped_zeros++;
                } else {
                    $set_evid_two = 1;
                    $indiv_set_evid_two = 1;
                    $a[$evid_column] = 2;
                    $row = join ',', @a;
                }
            }
        }
        if (not $indiv_set_evid_two and not exists $self->numobs_indiv->{$individual->idnumber}) {
            $self->numobs_indiv->{$individual->idnumber} = $numzeros;
        }
    }

    return $set_evid_two;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
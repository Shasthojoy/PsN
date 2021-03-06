package model_approximations;

use strict;
use warnings;
use include_modules;
use MooseX::Params::Validate;
use model_transformations;

sub second_order_derivatives_model
{
    # Create a model that can generate the second order derivatives
    my %parm = validated_hash(\@_,
        model => { isa => 'model' },
    );
    my $model = $parm{'model'};

    my $have_evid = $model->problems->[0]->inputs->[0]->have_column(column => 'EVID');
    if ($model->has_code(record => 'pk')) {
        $have_evid = 1;
    }

    my $derivatives_model = $model->copy(filename => 'derivatives.mod', write_copy => 0);
    my $netas = $derivatives_model->nomegas->[0];

    my @reset_code;
    push @reset_code, "IF (NEWIND.LT.2) THEN\n";
    for (my $i = 1; $i <= $netas; $i++) {
        push @reset_code, "    DYDETA${i}_ = 0\n";
    }
    for (my $i = 1; $i <= $netas; $i++) {
        for (my $j = 1; $j <= $i; $j++) {
            push @reset_code, "    D2YDETA$j${i}_ = 0\n";
        }
    }
    push @reset_code, "    MYY_ = 0\n";
    push @reset_code, "ENDIF\n";

    model_transformations::prepend_code(model => $derivatives_model, code => \@reset_code);

    my @derivatives_code;
    push @derivatives_code, "TMP2_ = Y\n";
    push @derivatives_code, "\"LAST\n";
    if ($have_evid) {
        push @derivatives_code, "\"    IF (EVID.EQ.0) THEN !Only obs records\n";
    }
    for (my $i = 1; $i <= $netas; $i++) {
        push @derivatives_code, "\"        DYDETA${i}_ = DYDETA${i}_ + G($i,1)\n";
    }
    for (my $i = 1; $i <= $netas; $i++) {
        for (my $j = 1; $j <= $i; $j++) {
            push @derivatives_code, "\"        D2YDETA$j${i}_ = D2YDETA$j${i}_ + G($i," . ($j + 1) . ")\n";
        }
    }

    push @derivatives_code, "\"        MYY_ = MYY_ + TMP2_  ! The log likelihood\n";
    if ($have_evid) {
        push @derivatives_code, "\"    ENDIF\n";
    }

    my $code_record;
    if ($model->has_code(record => 'pk')) {
        $code_record = 'error';
    } else {
        $code_record = 'pred';
    }
    model_transformations::append_code(model => $derivatives_model, code => \@derivatives_code, record => $code_record);

    $derivatives_model->remove_records(type => 'estimation');
    $derivatives_model->add_records(type => 'estimation', record_strings => [ "MAXEVAL=0 METHOD=1 LAPLACE -2LL" ]);
    $derivatives_model->remove_records(type => 'table');
    my @table;
    push @table, "FORMAT=s1PE30.15", "ID", "DV", "TIME", "MYY_";
    for (my $i = 1; $i <= $netas; $i++) {
        push @table, "ETA$i";
    }
    for (my $i = 1; $i <= $netas; $i++) {
        push @table, "DYDETA${i}_";
    }
    for (my $i = 1; $i <= $netas; $i++) {
        for (my $j = 1; $j <= $i; $j++) {
            push @table, "D2YDETA$j${i}_";
        }
    }
    if ($have_evid) {
        push @table, "EVID";
    }
    push @table, "NOPRINT", "ONEHEADER", "FILE=2nd_order.dta";
    $derivatives_model->add_records(type => 'table', record_strings => [ join ' ', @table ]);

    return $derivatives_model;
}

sub second_order_approximation_model
{
    # Create a model that can generate the second order derivatives
    my %parm = validated_hash(\@_,
        model => { isa => 'model' },
    );
    my $model = $parm{'model'};

    my $have_evid = $model->problems->[0]->inputs->[0]->have_column(column => 'EVID');
    if ($model->has_code(record => 'pk')) {
        $have_evid = 1;
    }

    my $netas = $model->nomegas->[0];

    my $input = "\$INPUT ID DV TIME MYY ";
    for (my $i = 1; $i <= $netas; $i++) {
        $input .= "EBE$i ";
    }
    for (my $i = 1; $i <= $netas; $i++) {
        $input .= "DYDETA$i ";
    }
    for (my $i = 1; $i <= $netas; $i++) {
        for (my $j = 1; $j <= $i; $j++) {
            $input .= "D2YDETA$j$i ";
        }
    }
    if ($have_evid) {
        $input .= "EVID";
    }

    my $sh_mod = model::shrinkage_module->new(
        nomegas => 1,
        directory => '',
        problem_number => 1
    );

    my $ignore = ""; 
    if ($have_evid) {
        $ignore = " IGNORE=(EVID.GT.0)";
    }

    my $problem = model::problem->new(
        ignore_missing_files=> 1,
        prob_arr => [
            '$PROBLEM Second order approximation', 
            $input,
            '$DATA 2nd_order.dta IGNORE=@' . $ignore,
        ],
        shrinkage_module => $sh_mod,
    );
    my $approximation_model = model->new(
        filename => 'approximated.mod',
        problems => [ $problem ],
        ignore_missing_files => 1,
        psn_record_order => 1,
    );
    
    $approximation_model->add_records(type => 'estimation', record_strings => [ 'MAXEVAL=9999 METHOD=1 LAPLACE -2LL' ]);
    $approximation_model->problems->[0]->omegas($model->problems->[0]->omegas);

    my @pred;

    push @pred, "Y = 0  ; No contribution to log like for the other rows\n";
    push @pred, "IF (NDREC.EQ.LIREC) THEN   ; Only for last record/subject\n";
    for (my $i = 1; $i <= $netas; $i++) {
        push @pred, "DELTA_ETA_$i = (ETA($i) - EBE$i)\n";
    }
    # 0th and 1st order
    my @first_order;
    push @first_order, "MYY";       # 0th order
    for (my $i = 1; $i <= $netas; $i++) {
        my $term = "TERM_O1_$i";
        push @pred, "$term = DYDETA$i * DELTA_ETA_$i\n";
        push @first_order, $term;
    }
    push @pred, "TMP1 = " . join(' + ', @first_order) . "\n";

    # 2nd order
    my @second_order1;
    for (my $i = 1; $i <= $netas; $i++) {
        my $term = "TERM_O2_$i";
        push @pred, "$term = DELTA_ETA_$i**2 * D2YDETA$i$i\n";
        push @second_order1, $term;
    }
    push @pred, "TMP2 = TMP1 + 1/2*(" . join(' + ', @second_order1) . ")\n";

    my @second_order2;
    for (my $i = 1; $i < $netas; $i++) {
        for (my $j = $i + 1; $j <= $netas; $j++) {
            my $term = "TERM_O3_$i$j";
            push @pred, "$term = DELTA_ETA_$i * DELTA_ETA_$j * D2YDETA$i$j\n";
            push @second_order2, $term;
        }
    } 
    push @pred, "Y = TMP2 + " . join(" + ", @second_order2) . "\n";

    push @pred, "ENDIF\n"; 

    $approximation_model->add_records(type => 'pred', record_strings => \@pred); 


    return $approximation_model;
}

1;

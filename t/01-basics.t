#!perl

use 5.010;
use strict;
use warnings;
use Log::Any '$log';
use Test::More 0.96;

use Sub::Spec::GetArgs::Array qw(get_args_from_array);

my $spec;

$spec = {
    args => {
        arg1 => ['str*' => {}],
    },
};
test_getargs(
    name=>'no arg -> ok',
    spec=>$spec, array=>[],
    status=>200, args=>{},
);
test_getargs(
    name=>'extra arg -> 400',
    spec=>$spec, array=>[1],
    status=>400
);
test_getargs(
    name=>'allow_extra_elems=1',
    spec=>$spec, array=>[1], allow_extra_elems=>1,
    status=>200, array=>[],
);

$spec = {
    args => {
        arg1 => ['str*' => {arg_pos=>0}],
        arg2 => ['str*' => {arg_pos=>1}],
    },
};
test_getargs(
    name=>'arg1 only',
    spec=>$spec, array=>[1],
    status=>200, args=>{arg1=>1},
);
test_getargs(
    name=>'arg1 & arg2 (1)',
    spec=>$spec, array=>[1, 2],
    status=>200, args=>{arg1=>1, arg2=>2},
);
test_getargs(
    name=>'arg1 & arg2 (2)',
    spec=>$spec, array=>[2, 1],
    status=>200, args=>{arg1=>2, arg2=>1},
);

$spec = {
    args => {
        arg1 => ['array*' => {of=>'str*', arg_pos=>0, arg_greedy=>1}],
    },
};
test_getargs(
    name=>'arg_greedy (1)',
    spec=>$spec, array=>[1, 2, 3],
    status=>200, args=>{arg1=>[1, 2, 3]},
);

$spec = {
    args => {
        arg1 => ['str*' => {arg_pos=>0}],
        arg2 => ['array*' => {of=>'str*', arg_pos=>1, arg_greedy=>1}],
    },
};
test_getargs(
    name=>'arg_greedy (2)',
    spec=>$spec, array=>[1, 2, 3, 4],
    status=>200, args=>{arg1=>1, arg2=>[2, 3, 4]},
);

$spec = {
    args => {
        arg1 => ['str*' => {arg_pos=>0}],
        arg2 => ['str*' => {arg_pos=>1, arg_greedy=>1}],
    },
};
test_getargs(
    name=>'arg_greedy (3, string)',
    spec=>$spec, array=>[1, 2, 3, 4],
    status=>200, args=>{arg1=>1, arg2=>"2 3 4"},
);

DONE_TESTING:
done_testing();

sub test_getargs {
    my (%args) = @_;

    subtest $args{name} => sub {
        my %input_args = (array=>$args{array}, spec=>$args{spec});
        for (qw/allow_extra_elems/) {
            $input_args{$_} = $args{$_} if defined $args{$_};
        }
        my $res = get_args_from_array(%input_args);

        is($res->[0], $args{status}, "status=$args{status}")
            or diag explain $res;

        if ($args{args}) {
            is_deeply($res->[2], $args{args}, "result")
                or diag explain $res->[2];
        }
        #if ($args{post_test}) {
        #    $args{post_test}->();
        #}
    };
}


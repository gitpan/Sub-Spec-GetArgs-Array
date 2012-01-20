package Sub::Spec::GetArgs::Array;

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

use Data::Sah;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_args_from_array);

our $VERSION = '0.06'; # VERSION

our %SPEC;

sub _parse_schema {
    Data::Sah::normalize_schema($_[0]);
}

$SPEC{get_args_from_array} = {
    summary => 'Get subroutine arguments (%args) from array',
    description_fmt => 'org',
    description => <<'_',

Using information in sub spec's ~args~ clause (particularly the ~arg_pos~ and
~arg_greedy~ arg type clauses), extract arguments from an array into a hash
\%args, suitable for passing into subs.

Example:

: my $spec = {
:     summary => 'Multiply 2 numbers (a & b)',
:     args => {
:         a => ['num*' => {arg_pos=>0}],
:         b => ['num*' => {arg_pos=>1}],
:     }
: }

then ~get_args_from_array(array=>[2, 3], spec=>$spec)~ will produce:

: [200, "OK", {a=>2, b=>3}]

_
    args => {
        array => ['array*' => {
        }],
        spec => ['hash*' => {
        }],
        allow_extra_elems => ['bool' => {
            default => 0,
            summary => 'Allow extra/unassigned elements in array',
            description_fmt => 'org',
            description => <<'_',

If set to 1, then if there are array elements unassigned to one of the arguments
(due to missing ~arg_pos~, for example), instead of generating an error, the
function will just ignore them.

_
        }],
    },
};
sub get_args_from_array {
    my %input_args = @_;
    # don't assign this to $array, we have @array too, avoid error-prone
    $input_args{array} or return [400, "Please specify array"];
    my $sub_spec   = $input_args{spec};
    my $args_spec  = $input_args{_args_spec};
    if (!$args_spec) {
        $args_spec = $sub_spec->{args} // {};
        $args_spec = { map { $_ => _parse_schema($args_spec->{$_}) }
                           keys %$args_spec };
    }
    my $allow_extra_elems = $input_args{allow_extra_elems} // 0;
    return [400, "Please specify spec"] if !$sub_spec && !$args_spec;
    #$log->tracef("-> get_args_from_array(), array=%s", $array);

    my @array = @{$input_args{array}};
    my $args = {};

    for my $i (reverse 0..$#array) {
        #$log->tracef("i=$i");
        while (my ($name, $schema) = each %$args_spec) {
            my $schema = $args_spec->{$name};
            my $ah0 = $schema->{clause_sets}[0];
            my $o = $ah0->{arg_pos};
            if (defined($o) && $o == $i) {
                if ($ah0->{arg_greedy}) {
                    my $type = $schema->{type};
                    my @elems = splice(@array, $i);
                    if ($type eq 'array') {
                        $args->{$name} = \@elems;
                    } else {
                        $args->{$name} = join " ", @elems;
                    }
                    #$log->tracef("assign %s to arg->{$name}", $args->{$name});
                } else {
                    $args->{$name} = splice(@array, $i, 1);
                    #$log->tracef("assign %s to arg->{$name}", $args->{$name});
                }
            }
        }
    }

    return [400, "There are extra, unassigned elements in array: [".
                join(", ", @array)."]"] if @array && !$allow_extra_elems;

    [200, "OK", $args];
}

1;
#ABSTRACT: Get subroutine arguments from array


=pod

=head1 NAME

Sub::Spec::GetArgs::Array - Get subroutine arguments from array

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use Sub::Spec::GetArgs::Array;

 my $res = get_args_from_array(array=>\@ary, spec=>$spec, ...);

=head1 DESCRIPTION

B<NOTICE>: This module and the L<Sub::Spec> standard is deprecated as of Jan
2012. L<Rinci> is the new specification to replace Sub::Spec, it is about 95%
compatible with Sub::Spec, but corrects a few issues and is more generic.
C<Perinci::*> is the Perl implementation for Rinci and many of its modules can
handle existing Sub::Spec sub specs.

This module provides get_args_from_array() (and gencode_get_args_from_array(),
upcoming). This module is used by, among others, L<Sub::Spec::GetArgs::Argv> and
L<Sub::Spec::Wrapper>.

This module uses L<Log::Any> for logging framework.

This module's functions has L<Sub::Spec> specs.

=head1 FUNCTIONS

None are exported by default, but they are exportable.

=head2 get_args_from_array(%args) -> [STATUS_CODE, ERR_MSG, RESULT]


Get subroutine arguments (%args) from array.

Using information in sub spec's ~args~ clause (particularly the ~arg_pos~ and
~arg_greedy~ arg type clauses), extract arguments from an array into a hash
\%args, suitable for passing into subs.

Example:

: my $spec = {
:     summary => 'Multiply 2 numbers (a & b)',
:     args => {
:         a => ['num*' => {arg_pos=>0}],
:         b => ['num*' => {arg_pos=>1}],
:     }
: }

then ~get_args_from_array(array=>[2, 3], spec=>$spec)~ will produce:

: [200, "OK", {a=>2, b=>3}]

Returns a 3-element arrayref. STATUS_CODE is 200 on success, or an error code
between 3xx-5xx (just like in HTTP). ERR_MSG is a string containing error
message, RESULT is the actual result.

Arguments (C<*> denotes required arguments):

=over 4

=item * B<allow_extra_elems> => I<bool> (default C<0>)

Allow extra/unassigned elements in array.

If set to 1, then if there are array elements unassigned to one of the arguments
(due to missing ~arg_pos~, for example), instead of generating an error, the
function will just ignore them.

=item * B<array>* => I<array>

=item * B<spec>* => I<hash>

=back

=head1 SEE ALSO

L<Sub::Spec>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


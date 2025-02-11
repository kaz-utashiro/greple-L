package App::Greple::L;

use v5.14;
use warnings;

our $VERSION = '1.00';

=head1 NAME

L - Greple module to produce result by line numbers

=head1 SYNOPSIS

greple -ML

=head1 VERSION

Version 1.00

=head1 DESCRIPTION

This module allows you to use line numbers to specify patterns or
regions which can be used in B<greple> options.

=over 7

=item B<-L>=I<line numbers>

Simply, next command will show 200th line with before/after 10 lines
of the file:

    greple -ML -L 200 -C10 file

If you don't like lines displayed with color, use B<--nocolor> option
or set colormap to something do nothing like B<--cm=N>.

Multiple lines can be specified by joining with comma:

    greple -ML -L 10,20,30

It is ok to use B<-L> option multiple times, like:

    greple -ML -L 10 -L 20 -L 30

But this command produce nothing, because each line definitions are
taken as a different pattern, and B<greple> prints lines only when all
patterns matched.  You can relax the condition by C<--need 1> option
in such case, then you will get expected result.  Next example will
display 10th, 20th and 30th lines in different colors.

    greple -ML -L 10 -L 20 -L 30 --need 1

Range can be specified by colon:

    greple -ML -L 10:20

You can also specify the step with range.  Next command will print
all even lines from line 10 to 20:

    greple -ML -L 10:20:2

Any of them can be omitted.  Next commands print all, odd and even
lines.

    greple -ML -L ::		# all lines
    greple -ML -L ::2	# odd lines
    greple -ML -L 2::2	# even lines

If start and end number is negative, they are subtracted from the
maxmum line number.  If the end number is prefixed by plus (`+') sign,
it is summed with start number.  Next commands print top and last 10
lines respectively.

    greple -ML -L :+9	# top 10 lines
    greple -ML -L -9:	# last 10 lines

Next example print all lines of the file, each line in four different
colors.

    greple -ML -L=1::4 -L=2::4 -L=3::4 -L=4::4 --need 1

If forth parameter is given, it describes how many lines is included
in that step cycle.  For example, next command prints top 3 lines in
every 10 lines.

    greple -ML -L ::10:3

When step count is omitted, forth value is used if available.  Next
command print every 10 lines in different colors.

    greple -ML -L :::10 --ci=A /etc/services

=item B<-ML> I<line numbers>

If a line number argument immediately follows B<-ML> module option,
it is recognized as a line number without the C<-L> option. Thus, the
above example can also be specified as follows:

    greple -ML ::10:3

When this notation is used, the option C<--cm N> is added to disable
coloring of matched portion.  This is to make it easier to use as a
filter to extract a specific range of lines.

=item B<L>=I<line numbers>

This notation just define function spec, which can be used in
patterns, as well as blocks and regions.  Actually, B<-L>=I<line> is
equivalent to B<--le> B<L>=I<line>.

Next command show patterns found in line number 1000-2000 area.

    greple -ML --inside L=1000:+1000 pattern

Next command prints all 10 line blocks which include the pattern.

    greple -ML --block L=:::10 pattern

In this case, however, it is faster and easier to use regex.

    greple --block '(.*\n){1,10}' pattern

=item B<--offload>=I<command>

Set the offload command to retrieve the desired line numbers. The
numbers in the output, starting at the beginning of the line, are
treated as line numbers.  This is compatible with B<grep -n> output.

Next command print 10 to 20 lines.

    greple -ML --offload 'seq 10 20'

=back

Using this module, it is impossible to give single C<L> in command
line arguments.  Use like B<--le=L> to search letter C<L>.  You have a
file named F<L>?  Stop substitution by placing C<--> before the target
files.

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::L

=head2 GITHUB

    $ cpanm https://github.com/kaz-utashiro/greple-L.git

=head1 SEE ALSO

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

L<Getopt::EX::Numbers>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2014-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use Carp;
use List::Util qw(min max reduce);
use Data::Dumper;

use Exporter qw(import);
our @EXPORT = qw(&line &offload);

use List::Util qw(any pairmap);
use App::Greple::Common;
use App::Greple::Regions qw(match_borders borders_to_regions);

my %param = (
    auto => 1,
);

sub finalize {
    my($app, $argv) = @_;
    $param{auto} or return;
    my $update = 0;
    for (my $i = 0; $i < @$argv; $i++) {
	local $_ = $argv->[$i];
	(/^-?[\d:,]+$/ and ! -f $_) or last;
	splice(@$argv, $i, 1, '--le', sprintf("&line(%s)", $_));
	$i++;
	$update++;
    }
    if ($update > 0) {
	my @default = qw(--cm N);
	push @default, qw(--need=1) if $update > 1;
	$app->setopt(default => @default);
    }
}

sub line_to_region {
    state $target = -1;
    state @lines;
    if ($target != \$_) {
	@lines = ([0, 0], borders_to_regions match_borders qr/^/m);
	$target = \$_;
    }
    use Getopt::EX::Numbers;
    my $numbers = Getopt::EX::Numbers->new(min => 1, max => $#lines);
    my @result = do {
	map  { [ $lines[$_->[0]]->[0], $lines[$_->[1]]->[1] ] }
	sort { $a->[0] <=> $b->[0] }
	map  { $numbers->parse($_)->range }
	map  { split /,+/ }
	@_;
    };
    @result;
}

sub line {
    my @lines = pairmap { $a ne &FILELABEL ? $a : () } @_;
    line_to_region(@lines);
}

sub line_to_range {
    map { @$_ } reduce {
	if (@$a > 0 and $a->[-1][1] + 1 == $b) {
	    $a->[-1][1] = $b;
	} else {
	    push @$a, [ $b, $b ];
	}
	$a;
    } [], @_;
}

sub range_to_spec {
    map {
	my($a, $b) = @$_;
	$a == $b ? "$a" : "$a:$b"
    } @_;
}

sub offload {
    our $offload_command;
    my $result = qx($offload_command) || die "$offload_command: exec error\n";
    line_to_region(range_to_spec(line_to_range($result =~ /^\d+/mg)));
}

1;

__DATA__

builtin offload-command=s $offload_command

option --offload --le &offload --offload-command

option L &line=$<shift>
help   L Region spec by line number

option -L --le L=$<shift>
help   -L Line number (1 10,20:30,40 -100 500: 1:1000:100 1::2)

[![Actions Status](https://github.com/kaz-utashiro/greple-L/workflows/test/badge.svg)](https://github.com/kaz-utashiro/greple-L/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-L.svg)](https://metacpan.org/release/App-Greple-L)
# NAME

L - Greple module to produce result by line numbers

# SYNOPSIS

greple -ML

# VERSION

Version 1.00

# DESCRIPTION

This module allows you to use line numbers to specify patterns or
regions which can be used in **greple** options.

- **-L**=_line numbers_

    Simply, next command will show 200th line with before/after 10 lines
    of the file:

        greple -ML -L 200 -C10 file

    If you don't like lines displayed with color, use **--nocolor** option
    or set colormap to something do nothing like **--cm=N**.

    Multiple lines can be specified by joining with comma:

        greple -ML -L 10,20,30

    It is ok to use **-L** option multiple times, like:

        greple -ML -L 10 -L 20 -L 30

    But this command produce nothing, because each line definitions are
    taken as a different pattern, and **greple** prints lines only when all
    patterns matched.  You can relax the condition by `--need 1` option
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

        greple -ML -L ::            # all lines
        greple -ML -L ::2   # odd lines
        greple -ML -L 2::2  # even lines

    If start and end number is negative, they are subtracted from the
    maxmum line number.  If the end number is prefixed by plus (\`+') sign,
    it is summed with start number.  Next commands print top and last 10
    lines respectively.

        greple -ML -L :+9   # top 10 lines
        greple -ML -L -9:   # last 10 lines

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

- **-ML** _line numbers_

    If a line number argument immediately follows **-ML** module option,
    it is recognized as a line number without the `-L` option. Thus, the
    above example can also be specified as follows:

        greple -ML ::10:3

    When this notation is used, the option `--cm N` is added to disable
    coloring of matched portion.  This is to make it easier to use as a
    filter to extract a specific range of lines.

- **L**=_line numbers_

    This notation just define function spec, which can be used in
    patterns, as well as blocks and regions.  Actually, **-L**=_line_ is
    equivalent to **--le** **L**=_line_.

    Next command show patterns found in line number 1000-2000 area.

        greple -ML --inside L=1000:+1000 pattern

    Next command prints all 10 line blocks which include the pattern.

        greple -ML --block L=:::10 pattern

    In this case, however, it is faster and easier to use regex.

        greple --block '(.*\n){1,10}' pattern

- **--offload**=_command_

    Set the offload command to retrieve the desired line numbers. The
    numbers in the output, starting at the beginning of the line, are
    treated as line numbers.  This is compatible with **grep -n** output.

    Next command print 10 to 20 lines.

        greple -ML --offload 'seq 10 20'

Using this module, it is impossible to give single `L` in command
line arguments.  Use like **--le=L** to search letter `L`.  You have a
file named `L`?  Stop substitution by placing `--` before the target
files.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::L

## GITHUB

    $ cpanm https://github.com/kaz-utashiro/greple-L.git

# SEE ALSO

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[Getopt::EX::Numbers](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3ANumbers)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2014-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Encode qw(decode encode FB_CROAK);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);

my ($from, $input, $output);
my ($force, $help) = (0, 0);

GetOptions(
    'from=s'   => \$from,
    'input=s'  => \$input,
    'output=s' => \$output,
    'force'    => \$force,
    'help'     => \$help,
) or usage(2);

usage(0) if $help;
usage(2) unless defined $from && defined $input && defined $output;
usage(2) if $input eq $output;

die "input file does not exist: $input\n" unless -f $input;
die "output file already exists: $output\n"
    if -e $output && !$force;

my $source_bytes = read_bytes($input);
my $text = eval { decode($from, $source_bytes, FB_CROAK) };
if ($@) {
    my $error = $@;
    chomp $error;
    die "could not decode '$input' as $from: $error\n";
}

# Remove a UTF-8 BOM after decoding. The output is always UTF-8 without a BOM.
$text =~ s/\A\x{FEFF}//;

my $utf8_bytes = eval { encode('UTF-8', $text, FB_CROAK) };
if ($@) {
    my $error = $@;
    chomp $error;
    die "could not encode converted text as UTF-8: $error\n";
}

write_bytes($output, $utf8_bytes);
print "converted $input ($from) -> $output (UTF-8)\n";

exit 0;

sub usage {
    my ($status) = @_;
    my $stream = $status == 0 ? *STDOUT : *STDERR;
    print {$stream} <<'USAGE';
Usage:
  perl convert-to-utf8.pl --from ENCODING --input INPUT --output OUTPUT [--force]

Options:
  --from ENCODING  Encoding of the input file, for example GBK or UTF-8.
  --input FILE     File to read.
  --output FILE    New UTF-8 file to write.
  --force          Replace the output file if it already exists.

The script never guesses the input encoding. It leaves the input file
unchanged and writes UTF-8 without a byte-order mark.
USAGE
    exit $status;
}

sub read_bytes {
    my ($file) = @_;
    open my $fh, '<:raw', $file or die "read $file: $!\n";
    local $/;
    my $bytes = <$fh>;
    close $fh or die "close $file: $!\n";
    return $bytes;
}

sub write_bytes {
    my ($file, $bytes) = @_;
    my $temporary = File::Spec->catfile(
        dirname($file),
        ".convert-to-utf8-$$.tmp",
    );

    open my $fh, '>:raw', $temporary
        or die "write temporary file $temporary: $!\n";
    print {$fh} $bytes or die "write temporary file $temporary: $!\n";
    close $fh or die "close temporary file $temporary: $!\n";

    rename $temporary, $file
        or do {
            unlink $temporary;
            die "replace $file: $!\n";
        };
}

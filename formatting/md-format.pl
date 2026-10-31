#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Encode qw(decode encode FB_CROAK);
use File::Find qw(find);
use File::Spec;
use Getopt::Long qw(GetOptions);

my $check = 0;
my $write = 0;

GetOptions(
    'check' => \$check,
    'write' => \$write,
) or usage(2);

usage(2) if $check && $write;
usage(2) unless $check || $write;
usage(2) unless @ARGV;

my @files = markdown_files(@ARGV);
usage(2) unless @files;

my $changed = 0;
my @results;
for my $file (@files) {
    my ($before, $after) = format_file($file);
    next if $before eq $after;

    $changed = 1;
    push @results, [$file, $before, $after];
}

if ($write) {
    # All files have already been decoded successfully before any file is changed.
    for my $result (@results) {
        my ($file, undef, $after) = @{$result};
        write_file($file, $after);
        print "formatted $file\n";
    }
} else {
    for my $result (@results) {
        print_diff(@{$result});
    }
}

exit($check && $changed ? 1 : 0);

sub usage {
    my ($status) = @_;
    print STDERR <<"USAGE";
Usage:
  perl md-format.pl --check FILE_OR_DIRECTORY ...
  perl md-format.pl --write FILE_OR_DIRECTORY ...

USAGE
    exit $status;
}

sub markdown_files {
    my @paths = @_;
    my @files;

    for my $path (@paths) {
        if (-f $path) {
            push @files, $path if $path =~ /\.md\z/i;
            next;
        }

        die "not found: $path\n" unless -d $path;
        find(
            {
                no_chdir => 1,
                wanted   => sub {
                    return unless -f $_;
                    push @files, $File::Find::name if /\.md\z/i;
                },
            },
            $path,
        );
    }

    return sort @files;
}

sub format_file {
    my ($file) = @_;
    open my $fh, '<:raw', $file or die "read $file: $!\n";
    local $/;
    my $bytes = <$fh>;
    close $fh or die "close $file: $!\n";

    my $text = eval { decode('UTF-8', $bytes, FB_CROAK) };
    if ($@) {
        my $error = $@;
        chomp $error;
        die "invalid UTF-8 in $file: $error\n";
    }

    my @protected;
    my $body = protect_fenced_code($text, \@protected);
    $body = protect_fragments($body, \@protected);
    $body = format_plain_text($body);
    $body = restore_fragments($body, \@protected);

    return ($text, $body);
}

sub protect_fenced_code {
    my ($text, $protected) = @_;
    my @lines = split /(?<=\n)/, $text, -1;
    my $inside = 0;
    my $fence = '';
    my $result = '';

    for my $line (@lines) {
        if (!$inside && $line =~ /^ {0,3}(`{3,}|~{3,})/) {
            $inside = 1;
            $fence = $1;
            $result .= protect($line, $protected);
            next;
        }

        if ($inside) {
            $result .= protect($line, $protected);
            if ($line =~ /^ {0,3}\Q$fence\E[ \t]*(?:\r?\n)?\z/) {
                $inside = 0;
                $fence = '';
            }
            next;
        }

        $result .= $line;
    }

    return $result;
}

sub protect_fragments {
    my ($text, $protected) = @_;

    # Protect GitHub-style Markdown Alert markers before punctuation changes.
    $text =~ s{(^[ \t]{0,3}>[ \t]*\[![A-Za-z][A-Za-z0-9_-]*\])}{protect($1, $protected)}gme;

    # Protect complete Markdown links and images before punctuation changes.
    $text =~ s{(!?\[[^\]\n]*\]\([^)\n]*\))}{protect($1, $protected)}ge;

    # Protect inline code, URLs and HTML tags.
    $text =~ s{(`+[^`\n]*`+)}{protect($1, $protected)}ge;
    $text =~ s{(https?://[^\s<>()]+)}{protect($1, $protected)}ge;
    $text =~ s{(<\/?[A-Za-z][^>\n]*>)}{protect($1, $protected)}ge;

    return $text;
}

sub protect {
    my ($value, $protected) = @_;
    my $index = @{$protected};
    push @{$protected}, $value;
    return "\x00MD_FORMAT_PROTECTED_${index}\x00";
}

sub restore_fragments {
    my ($text, $protected) = @_;
    $text =~ s{\x00MD_FORMAT_PROTECTED_(\d+)\x00}{$protected->[$1]}ge;
    return $text;
}

sub format_plain_text {
    my ($text) = @_;

    # Keep Chinese full stops distinguishable from existing ASCII periods.
    # An ASCII period after an English word may be an abbreviation or decimal.
    $text =~ s/。/\x00MD_FORMAT_FULL_STOP\x00/g;
    $text =~ tr/；：，！？/;:,!?/;
    $text =~ s/“([^"\n]*)”/"$1"/g;
    $text =~ s/‘([^'\n]*)’/'$1'/g;

    # Normalize paired double quotes without adding spaces at line edges.
    $text =~ s/(?<=\S)[ \t]*"[ \t]*([^"\n]*?)[ \t]*"[ \t]*(?=\S)/ "$1" /g;

    $text = normalize_punctuation($text, ',');
    $text = normalize_punctuation($text, ':');
    $text = normalize_punctuation($text, ';');
    $text = normalize_punctuation($text, '!');
    $text = normalize_punctuation($text, '?');
    $text = normalize_full_stops($text);
    $text = normalize_periods($text);

    return $text;
}

sub normalize_full_stops {
    my ($text) = @_;
    my $marker = quotemeta("\x00MD_FORMAT_FULL_STOP\x00");

    $text =~ s/(?<=\S)[ \t]*$marker[ \t]*(?=\S)/ . /g;
    $text =~ s/(?<=\S)[ \t]*$marker[ \t]*(?=\r?\n|\z)/ ./g;
    $text =~ s/(?<!\S)[ \t]*$marker[ \t]*(?=\S)/. /g;
    return $text;
}

sub normalize_punctuation {
    my ($text, $punctuation) = @_;
    my $quoted = quotemeta($punctuation);

    # Text on both sides: keep one horizontal space on both sides.
    $text =~ s/(?<=\S)[ \t]*$quoted[ \t]*(?=\S)/ $punctuation /g;

    # End of line or file: keep the space before punctuation, never after it.
    $text =~ s/(?<=\S)[ \t]*$quoted[ \t]*(?=\r?\n|\z)/ $punctuation/g;

    # Start of line: never add leading whitespace.
    $text =~ s/(?<!\S)[ \t]*$quoted[ \t]*(?=\S)/$punctuation /g;
    return $text;
}

sub normalize_periods {
    my ($text) = @_;
    $text =~ s/(?<![A-Za-z0-9_])(?<=\S)[ \t]*\.[ \t]*(?=\S)/ . /g;
    $text =~ s/(?<![A-Za-z0-9_])(?<=\S)[ \t]*\.[ \t]*(?=\r?\n|\z)/ ./g;
    $text =~ s/(?<!\S)[ \t]*\.[ \t]*(?=\S)/. /g;
    return $text;
}

sub write_file {
    my ($file, $text) = @_;
    my $bytes = eval { encode('UTF-8', $text, FB_CROAK) };
    if ($@) {
        my $error = $@;
        chomp $error;
        die "could not encode $file as UTF-8: $error\n";
    }

    open my $fh, '>:raw', $file or die "write $file: $!\n";
    print {$fh} $bytes or die "write $file: $!\n";
    close $fh or die "close $file: $!\n";
}

sub print_diff {
    my ($file, $before, $after) = @_;
    my $temp_before = File::Spec->catfile(File::Spec->tmpdir, "md-format-before-$$");
    my $temp_after = File::Spec->catfile(File::Spec->tmpdir, "md-format-after-$$");

    write_file($temp_before, $before);
    write_file($temp_after, $after);
    system(
        'diff',
        '-u',
        '--label', "$file (before)",
        '--label', "$file (after)",
        $temp_before,
        $temp_after,
    );
    unlink $temp_before, $temp_after;
}

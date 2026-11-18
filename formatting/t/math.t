use strict;
use warnings;
use utf8;
use Encode qw(encode decode FB_CROAK);
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use Test::More;

my $script = File::Spec->catfile($FindBin::Bin, '..', 'md-format.pl');
my $dir = tempdir(CLEANUP => 1);
my $file = File::Spec->catfile($dir, 'sample.md');

sub write_text {
    my ($text) = @_;
    open my $fh, '>:raw', $file or die $!;
    print {$fh} encode('UTF-8', $text);
    close $fh or die $!;
}

sub read_text {
    open my $fh, '<:raw', $file or die $!;
    local $/;
    return decode('UTF-8', scalar <$fh>, FB_CROAK);
}

sub run_formatter {
    my ($mode) = @_;
    open my $fh, '-|', $^X, $script, $mode, $file or die $!;
    local $/;
    my $output = <$fh>;
    close $fh;
    return ($? >> 8, $output // '');
}

my @cases = (
    ['math only', '$n!,x:y$', '$n!,x:y$'],
    ['inline dollar', '公式：$n!, x:y，z。$。', '公式 : $n!, x:y，z。$ .'],
    ['display dollar', "公式：\n\$\$\nx!, y:z，甲。\n\$\$\n结束。",
        "公式 :\n\$\$\nx!, y:z，甲。\n\$\$\n结束 ."],
    ['parentheses', '公式：\(n!, x:y，z。\)。', '公式 : \(n!, x:y，z。\) .'],
    ['multiline parentheses', "\\(\nx!,y:z\n\\)\n正文。",
        "\\(\nx!,y:z\n\\)\n正文 ."],
    ['brackets', "公式：\n\\[\nx!, y:z，甲。\n\\]\n结束。",
        "公式 :\n\\[\nx!, y:z，甲。\n\\]\n结束 ."],
    ['multiple', '甲：$x!$，乙：\(y:z\)。', '甲 : $x!$ , 乙 : \(y:z\) .'],
    ['escaped dollar in math', '甲：$x+\$5, n!$。', '甲 : $x+\$5, n!$ .'],
    ['currency', '价格 $5，另一个 $10。', '价格 $5 , 另一个 $10 .'],
    ['escaped dollars', '价格 \$5，\$10。', '价格 \$5 , \$10 .'],
    ['whitespace dollars', '甲 $ x，y $ 乙。', '甲 $ x , y $ 乙 .'],
    ['unmatched', '公式 $x，下一句。', '公式 $x , 下一句 .'],
    ['unmatched display', "公式 \$\$x，\n结束。", "公式 \$\$x ,\n结束 ."],
    ['inline cannot cross lines', "甲 \$x，\ny\$ 乙。", "甲 \$x ,\ny\$ 乙 ."],
    ['escaped parentheses', '甲 \\\\(x，y\\\\) 乙。', '甲 \\\\(x , y\\\\) 乙 .'],
    ['even slashes before dollar', '甲 \\\\$x,y$。', '甲 \\\\$x,y$ .'],
    ['inline code', '代码 `$x,y$，z!`，公式 $n!$。', '代码 `$x,y$，z!` , 公式 $n!$ .'],
    ['nested protection', '公式 $x+\text{`a,b`},n!$。', '公式 $x+\text{`a,b`},n!$ .'],
    ['link and image', '[标题，$x!$](https://example.com/a?b=c)，![图](pic.png)。',
        '[标题，$x!$](https://example.com/a?b=c) , ![图](pic.png) .'],
    ['code fence', "```c\n// \$x,y\$，原样。\n```\n正文。",
        "```c\n// \$x,y\$，原样。\n```\n正文 ."],
    ['no pairing across fence', "\$\$甲，\n```\nx\n```\n乙。\$\$",
        "\$\$甲 ,\n```\nx\n```\n乙 . \$\$"],
    ['triple dollars are literal', '$$$甲，乙$$$。', '$$$甲 , 乙$$$ .'],
    ['alert', '> [!NOTE]' . "\n" . '> 注意：$x!$。',
        '> [!NOTE]' . "\n" . '> 注意 : $x!$ .'],
    ['CRLF display', "\$\$\r\nx!,y:z\r\n\$\$\r\n正文。\r\n",
        "\$\$\r\nx!,y:z\r\n\$\$\r\n正文 .\r\n"],
    ['escaped bracket inside math', '甲：\[x\\\],y!\]。', '甲 : \[x\\\],y!\] .'],
    ['plain punctuation', '甲，乙；丙：丁！好吗？', '甲 , 乙 ; 丙 : 丁 ! 好吗 ?'],
    ['URL and HTML', '网址：https://example.com/a?b=c，' . "\n" . '<span title="甲，乙">正文。</span>',
        '网址 : https://example.com/a?b=c，' . "\n" . '<span title="甲，乙">正文 . </span>'],
);

for my $case (@cases) {
    my ($name, $input, $expected) = @$case;
    subtest $name => sub {
        write_text($input);
        my ($check) = run_formatter('--check');
        is($check, $input eq $expected ? 0 : 1, 'check status');
        is(read_text(), $input, 'check does not modify input');
        my ($write) = run_formatter('--write');
        is($write, 0, 'write succeeds');
        is(read_text(), $expected, 'exact formatted output');
        my ($clean) = run_formatter('--check');
        is($clean, 0, 'second check is clean');
        run_formatter('--write');
        is(read_text(), $expected, 'second write is idempotent');
        unlike(read_text(), qr/\x00MD_FORMAT_/, 'no leaked placeholders');
    };
}

done_testing();

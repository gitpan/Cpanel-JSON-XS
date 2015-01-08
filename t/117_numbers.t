use strict;
use Cpanel::JSON::XS;
use Test::More;
use Config;
plan tests => 19;

is encode_json([9**9**9]),         '[null]', "inf -> null";
is encode_json([-sin(9**9**9)]),   '[null]', "nan -> null";
is encode_json([-9**9**9]),        '[null]', "-inf -> null";
is encode_json([sin(9**9**9)]),    '[null]', "-nan -> null";
is encode_json([9**9**9/9**9**9]), '[null]', "-nan -> null";

my $json = Cpanel::JSON::XS->new->stringify_infnan;
my ($inf, $nan) =
  ($^O eq 'MSWin32') ? ('1.#INF','1.#QNAN') :
  ($^O eq 'solaris') ? ('Infinity','NaN') :
                       ('inf','nan');
my $neg_nan = ($^O eq 'MSWin32') ? "-1.#IND" : "-".$nan;
# newlib and glibc 2.5 have no -nan support, just nan
if ($^O eq 'cygwin' or ($Config{glibc_version} && $Config{glibc_version} < 2.6)) {
  $neg_nan = $nan;
}

is $json->encode([9**9**9]),         "[\"$inf\"]",  "inf -> \"inf\"";
is $json->encode([-9**9**9]),        "[\"-$inf\"]", "-inf -> \"-inf\"";
if ($^O eq 'MSWin32') {
  like $json->encode([-sin(9**9**9)]),   qr/\[\"($neg_nan|$nan)\"\]/,  "nan -> \"nan\"";
  like $json->encode([sin(9**9**9)]),    qr/\[\"($neg_nan|$nan)\"\]/, "-nan -> \"-nan\"";
  like $json->encode([9**9**9/9**9**9]), qr/\[\"($neg_nan|$nan)\"\]/, "-nan -> \"-nan\"";
} else {
  is $json->encode([-sin(9**9**9)]),   "[\"$nan\"]",  "nan -> \"nan\"";
  is $json->encode([sin(9**9**9)]),    "[\"$neg_nan\"]", "-nan -> \"-nan\"";
  is $json->encode([9**9**9/9**9**9]), "[\"$neg_nan\"]", "-nan -> \"-nan\"";
}

$json = Cpanel::JSON::XS->new->stringify_infnan(2);
is $json->encode([9**9**9]),         "[$inf]",  "inf";
is $json->encode([-9**9**9]),        "[-$inf]", "-inf";
if ($^O eq 'MSWin32') {
  like $json->encode([-sin(9**9**9)]),   qr/\[($neg_nan|$nan)\]/,  "nan";
  like $json->encode([sin(9**9**9)]),    qr/\[($neg_nan|$nan)\]/, "-nan";
  like $json->encode([9**9**9/9**9**9]), qr/\[($neg_nan|$nan)\]/, "-nan";
} else {
  is $json->encode([-sin(9**9**9)]),   "[$nan]",  "nan";
  is $json->encode([sin(9**9**9)]),    "[$neg_nan]", "-nan";
  is $json->encode([9**9**9/9**9**9]), "[$neg_nan]", "-nan";
}


my $num = 3;
my $str = "$num";
is encode_json({test => [$num, $str]}), '{"test":[3,"3"]}', 'int dualvar';

$num = 3.21;
$str = "$num";
is encode_json({test => [$num, $str]}), '{"test":[3.21,"3.21"]}', 'numeric dualvar';

$str = '0 but true';
$num = 1 + $str;
is encode_json({test => [$num, $str]}), '{"test":[1,"0 but true"]}', 'int/string dualvar';

$str = 'bar';
{ no warnings "numeric"; $num = 23 + $str }
is encode_json({test => [$num, $str]}), '{"test":[23,"bar"]}', , 'int/string dualvar';

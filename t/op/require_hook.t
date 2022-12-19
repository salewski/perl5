#!perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc( qw(../lib) );
}

use strict;
use warnings;

plan(tests => 4);

# Dedupe @INC. In a future patch we /may/ refuse to process items
# more than once and deduping here will prevent the tests from failing
# should we make that change.
my %seen; @INC = grep {!$seen{$_}++} @INC;
{
    # as of 5.37.7
    fresh_perl_like(
        '$SIG{__REQUIRE__} = "x";',
        qr!\$SIG\{__REQUIRE__\} may only be a CODE reference or undef!,
        { }, '$SIG{__REQUIRE__} forbids non code refs (string)');
}
{
    # as of 5.37.7
    fresh_perl_like(
        '$SIG{__REQUIRE__} = [];',
        qr!\$SIG\{__REQUIRE__\} may only be a CODE reference or undef!,
        { }, '$SIG{__REQUIRE__} forbids non code refs (array ref)');
}
{
    # as of 5.37.7
    fresh_perl_like(
        '$SIG{__REQUIRE__} = sub { die "Not allowed to load $_[0]" }; require Frobnitz;',
        qr!Not allowed to load Frobnitz\.pm!,
        { }, '$SIG{__REQUIRE__} exceptions stop require');
}
{
    # as of 5.37.7
    fresh_perl_is(
        'use lib "./lib/caller"; '.
        '$SIG{__REQUIRE__} = sub { my ($name)= @_; warn "before $name"; '.
        'return sub { warn "after $name" } }; require Apack;',
        <<'EOF_WANT',
before Apack.pm at - line 1.
before Bpack.pm at - line 1.
before Cpack.pm at - line 1.
after Cpack.pm at - line 1.
after Bpack.pm at - line 1.
after Apack.pm at - line 1.
EOF_WANT
        { }, '$SIG{__REQUIRE__} works as expected with t/lib/caller/Apack');
}

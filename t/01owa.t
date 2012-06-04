#!/usr/bin/env perl

use strict;

use Test::More tests => 19;
use Test::Recent qw(occured_within_ago);

ok(defined &occured_within_ago, "exported");

# now is not now
my $now = DateTime->new(
	year => '2012',
	month => '05',
	day => '23',
	hour => '10',
	minute => '36',
	second => '30',
	time_zone => 'Z',
);

# manually set the clock
$Test::Recent::OverridedNowForTesting =  $now;

my $ten = DateTime::Duration->new( seconds => 10 );
ok occured_within_ago($now, $ten), "DateTime now";
ok !occured_within_ago($now + DateTime::Duration->new( seconds => 1), $ten), "future";
ok occured_within_ago($now + DateTime::Duration->new( seconds => -1), $ten), "past";
ok !occured_within_ago($now + DateTime::Duration->new( seconds => -11), $ten), "too past";

ok occured_within_ago('2012-05-23T10:36:30Z', "10s"), "now";
ok !occured_within_ago('2012-05-23T10:36:31Z', "10s"), "future";
ok occured_within_ago('2012-05-23T10:36:29Z', "10s"), "past";
ok !occured_within_ago('2012-05-23T10:36:19Z', "10s"), "too past";

# test bad cases
ok !occured_within_ago("This is utter junk", $ten), "DateTime junk";
ok !occured_within_ago(undef, $ten), "DateTime undef";

# test timezones
ok occured_within_ago('2012-05-23T11:36:30+01:00', "10s"), "now";
ok !occured_within_ago('2012-05-23T11:36:31+01:00', "10s"), "future";
ok occured_within_ago('2012-05-23T11:36:29+01:00', "10s"), "past";
ok !occured_within_ago('2012-05-23T11:36:19+01:00', "10s"), "too past";
ok occured_within_ago('2012-05-23T06:36:30-04', "10s"), "now";
ok !occured_within_ago('2012-05-23T06:36:31-04', "10s"), "future";
ok occured_within_ago('2012-05-23T06:36:29-04', "10s"), "past";
ok !occured_within_ago('2012-05-23T06:36:19-04', "10s"), "too past";

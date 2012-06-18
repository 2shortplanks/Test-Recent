package Test::Recent;
use 5.006;

use base qw(Exporter);

use strict;
use Test::Builder::Tester;

use DateTime;
use Time::Duration::Parse qw(parse_duration);
use DateTime::Format::ISO8601;
use Scalar::Util qw(blessed);

#use Smart::Comments;

use vars qw(@EXPORT_OK $VERSION $OverridedNowForTesting);

$VERSION = "2.02";

my $tester = Test::Builder->new();

# utility regex
my $YMD    = qr/[0-9]{4}-[0-9]{2}-[0-9]{2}/x;
my $HMS    = qr/[0-9]{2}:[0-9]{2}:[0-9]{2}/x;
my $SUBSEC = qr/[0-9]+/x;
my $TZ     = qr/[+-][0-9]{2}/x;

sub _datetime($) {
	my $str = shift;
	return $str if blessed $str && $str->isa("DateTime");

	###
	# munge common extra formats into ISO8601
	###

	# postgres
	$str =~ s<\A ($YMD) [ ] ($HMS) [.] $SUBSEC ($TZ) \z><$1T$2$3>x;

	return eval { DateTime::Format::ISO8601->parse_datetime( $str ) };  ## no critic (RequireCheckingReturnValueOfEval)
}

sub occured_within_ago($$) {
	my $value = shift;
	return unless defined $value;

	my $time = _datetime($value);
	return unless defined $time;

	my $duration = shift;
	unless (blessed $duration && $duration->isa("DateTime::Duration")) {
		$duration = DateTime::Duration->new(
			seconds => parse_duration($duration)
		);
	}

	### time: $time->iso8601
	### duration: $duration

	my $now = $OverridedNowForTesting || DateTime->now();
	my $ago = $now - $duration;

	### now: $now->iso8601
	### ago: $ago->iso8601

	return if $now  < $time;
	return if $time < $ago;
	return 1;
}
push @EXPORT_OK, "occured_within_ago";

sub recent ($;$$) {
	my $time = shift;
	my $desc = pop || "recent time";
	my $duration = shift || "10s";

	my $ok = occured_within_ago($time, $duration);
	$tester->ok($ok, $desc);
	return 1 if $ok;
	$tester->diag("$time not recent");
	return;
}
push @EXPORT_OK, "recent";

1;

__END__

=head1 NAME

Test::Recent - check a time is recent

=head1 SYNOPSIS

   use Test::More;
   use Test::Recent qw(recent);

   # check things happened in the last ten seconds
   recent DateTime->now, "now is recent!";
   recent "2012-12-23 00:00:00", "end of mayan calendar happened recently?";

   # check things happened in the last hour
   recent "2012-12-23 00:00:00", DateTime::Duration->new( hours => 1 ), "mayan";
   recent "2012-12-23 00:00:00", "1 hour", "mayan"

=head1 DESCRIPTION

Simple module to check things happened recently.

=head2 Functions

These are exported on demand or may be called fully qualified

=over

=item recent $date_and_time

=item recent $date_and_time, $test_description

=item recent $date_and_time, $duration, $test_description

Tests (using the Test::Builder framework) if the time occured within the
duration ago from the current time.  If no duration is passed, ten seconds
is assumed.

=item occured_within_ago $date_and_time, $duration

Returns true if and only if the time occured within the duration ago from
the current time.

=back

=head2 Parsing of Datetimes

This module supports the following things being passed in as a date and time:

=over

=item A DateTime object

=item An ISO8601 formatted date string

i.e. anything that DateTime::Format::ISO8601 can parse

=item A Postgres style TIMESTAMP WITH TIME ZONE 

i.e. something of the form C<YYYY-MM-DD HH:MM:SS.ssssss+TZ>

=back

Older verions of this module used DateTimeX::Easy to parse the datetime, but
this proved to be unreliable.

=head1 AUTHOR

Written by Mark Fowler <mark@twoshortplanks.com>

=head1 COPYRIGHT

Copyright OmniTI 2012.  All Rights Rerserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

Bugs should be reported via this distribution's
CPAN RT queue.  This can be found at
L<https://rt.cpan.org/Dist/Display.html?Test-Recent>

You can also address issues by forking this distribution
on github and sending pull requests.  It can be found at
L<http://github.com/2shortplanks/Test-Recent>

In order not to depend on another DateTime library, this module converts
postgres style TIMESTAMP WITH TIME ZONE by using a regular expression and
simply ignoring microseconds.  This potentially introduces a one second
inaccuracy in the recent handling.

=head1 SEE ALSO

L<DateTime::Format::ISO8601>, L<Time::Duration::Parse>

=cut

1
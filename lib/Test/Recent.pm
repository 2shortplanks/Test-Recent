package Test::Recent;
use 5.006;

use base qw(Exporter);

use strict;
use Test::Builder::Tester;

use DateTime;
use Time::Duration::Parse qw(parse_duration);
use DateTime::Format::ISO8601;
use Scalar::Util qw(blessed);
use Carp qw(croak);

use vars qw(@EXPORT_OK $VERSION $OverridedNowForTesting $RelativeTo);

$VERSION = "2.05";

my $tester = Test::Builder->new();

# utility regex
my $YMD    = qr/[0-9]{4}-[0-9]{2}-[0-9]{2}/x;
my $HMS    = qr/[0-9]{2}:[0-9]{2}:[0-9]{2}/x;
my $SUBSEC = qr/[0-9]+/x;
my $TZ     = qr/[+-][0-9]{2}/x;
my $EPOCH  = qr/\A  \d+ (?:\.\d+)?  \z/x;

sub _datetime($) {
	my $str = shift;
	return unless defined $str;
	return $str if blessed $str && $str->isa("DateTime");

	###
	# is this epoch seconds?
	###

	if ($str =~ $EPOCH) {
		return DateTime->from_epoch( epoch => $str );
	}

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

	# forget the nanoseconds in the time passed to us.  This is necessary
	# because DateTime->now() doesn't return nanoseconds, so if we don't
	# forget nanoseconds what is passed in might actually be mistaken
	# for something in the future
	$time = $time->clone->set_nanosecond(0);

	my $duration = shift;
	unless (blessed $duration && $duration->isa("DateTime::Duration")) {
		$duration = DateTime::Duration->new(
			seconds => parse_duration($duration)
		);
	}

	# people can override time!
	my $now = $RelativeTo;
	if (defined $now) {
		$now = _datetime($now);
		unless (defined $now) {
			croak "\$Test::Recent::RelativeTo isn't parsable by Test::Recent";
		}
	}

	# historically we allowed $OverridedNowForTesting to be used to override
	# the sense of time.  If some muppet is still using this, let them
	$now = $OverridedNowForTesting unless defined $now;

	$now = DateTime->now() unless defined $now;

	my $ago = $now - $duration;

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

Tests (using the Test::Builder framework) if the time occurred within the
duration ago from the current time.  If no duration is passed, ten seconds
is assumed.

=item occured_within_ago $date_and_time, $duration

Returns true if and only if the time occurred within the duration ago from
the current time.

=back

=head2 Parsing of DateTimes

This module supports the following things being passed in as a date and time:

=over

=item epoch seconds

=item A DateTime object

=item An ISO8601 formatted date string

i.e. anything that DateTime::Format::ISO8601 can parse

=item A Postgres style TIMESTAMP WITH TIME ZONE 

i.e. something of the form C<YYYY-MM-DD HH:MM:SS.ssssss+TZ>

=back

Older versions of this module used DateTimeX::Easy to parse the datetime, but
this proved to be unreliable.

=head2 Overriding the sense of "now"

Sometimes you want someone else's concept of I<now>.  For example, you might
want to pull back the time from the database server and compare against that
rather than your own local clock.

This can be done by setting the C<$Test::Recent::RelativeTo> variable.  For
safety's sake, this should probably be done with local:

    {
        local $Test::Recent::RelativeTo =
            $dbh->selectcol_arrayref("SELECT NOW()")->[0];
        recent($time);
    }

You can set C<$Test::Recent::RelativeTo> to anything that Test::Recent can
parse.

=head1 AUTHOR

Written by Mark Fowler <mark@twoshortplanks.com>

=head1 COPYRIGHT

Copyright OmniTI 2012.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

This module ignores sub-seconds.  This is primarily because the current
implementation of DateTime's C<now> method does not return nanoseconds, meaning
that technically C<now> returns a time that is B<in the past> and might
occur before a timestamp you hand in that contained nanoseconds (and therefore
would erroneously be not concidered "recent")

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
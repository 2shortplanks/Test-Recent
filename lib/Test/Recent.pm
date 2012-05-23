package Test::Recent;
use base qw(Exporter);

use strict;
use Test::Builder::Tester;

use DateTime;
use DateTimeX::Easy qw(datetime);
use Time::Duration::Parse qw(parse_duration);
use Scalar::Util qw(blessed);

#use Smart::Comments;

use vars qw(@EXPORT_OK $VERSION $OverridedNowForTesting);

$VERSION = "1.00";

my $tester = Test::Builder->new();

sub occured_within_ago($$) {
	my $time = datetime(shift);

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
   recent "5 seconds ago", "5 seconds ago is obviously recently";

   # check things happened in the last hour
   recent "2012-12-23 00:00:00", DateTime::Duration->new( hours => 1 ), "mayan";
   recent "2012-12-23 00:00:00", "1 hour", "mayan"

=head1 DESCRIPTION

Simple module to check things happened recently.  Uses DateTimeX::Easy and
Time::Duration::Parse do parse the times and durations.

=head2 Functions

These are exported on demand or may be called fully qualified

=over

=item recent $time

=item recent $time, $test_description

=item recent $time, $duration, $test_description

Tests (using the Test::Builder framework) if the time occured within the
duration ago from the current time.  If no duration is passed, ten seconds
is assumed.

=item occured_within_ago $time, $duration

Returns true if and only if the time occured within the duration ago from
the current time.

=back

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

=head1 SEE ALSO

L<DateTimeX::Easy>, L<Time::Duration::Parse>

=cut

1
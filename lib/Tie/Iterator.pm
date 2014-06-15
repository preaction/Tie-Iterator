package Tie::Iterator;
# ABSTRACT: Work with an iterator like an array

use strict;
use warnings;
use feature qw( say );
use base qw( Exporter );
our @EXPORT = qw( );
our @EXPORT_OK = qw( list imap igrep isort :all );
our %EXPORT_TAGS = (
    all => [qw( list imap igrep isort )],
);

sub TIEARRAY {
    my ( $class, $iter ) = @_;
    return bless {
        _cache => [],
        _iter => $iter,
        _done => 0,
    }, "${class}::ARRAY";
}

sub TIEHANDLE {
    my ( $class, $iter ) = @_;
    return bless {
        _cache => [],
        _iter => $iter,
        _done => 0,
    }, "${class}::HANDLE";
}

sub generate_to {
    my ( $self, $i ) = @_;
    $i -= @{ $self->{_cache} };
    while ( my $item = $self->{_iter}->() ) {
        push @{ $self->{_cache} }, $item;
        return unless $i--;
    }
    $self->{_done} = 1;
    return;
}

sub list(\@) {
    my ( $ary ) = @_;
    if ( tied @$ary ) {
        my @retval;
        for my $i ( @$ary ) {
            push @retval, $i;
        }
        return @retval;
    }
    return @$ary;
}

sub imap(&\@) {
    my ( $sub, $ary ) = @_;
    if ( tied @$ary ) {
        tie my @retval, 'Tie::Iterator', sub {
            local $_ = shift @$ary;
            return $sub->();
        };
        return @retval;
    }
    return map { local $_ = $_; $sub->() } @$ary;
}

sub igrep(&\@) {
    warn "grep()";
}

sub isort(&\@) {
    warn "sort()";
}

package Tie::Iterator::ARRAY;

our @ISA = qw( Tie::Iterator );

sub FETCH {
    my ( $self, $i ) = @_;
    $self->generate_to( $i );
    return $self->{ _cache }[ $i ];
}

sub STORE {
    die "Unimplemented";
}

sub FETCHSIZE {
    my ( $self ) = @_;
    # Keep this thing going until we're done
    my $size = @{ $self->{_cache} } + 1 - $self->{_done};
    return $size;
}

sub STORESIZE {
    die "Unimplemented";
}

sub SHIFT {
    my ( $self ) = @_;
    $self->generate_to( 0 );
    return shift @{ $self->{_cache} };
}

package Tie::Iterator::HANDLE;

our @ISA = qw( Tie::Iterator );

sub READLINE {
    my ( $self ) = @_;
    $self->generate_to( 0 );
    return shift @{ $self->{_cache} };
}

1;
__END__

=head1 SYNOPSIS

    tie my @iter, 'Tie::Iterator', sub { };
    for my $item ( @iter ) {

    }

=head1 DESCRIPTION

This is an attempt to add a more-transparent iterator to Perl. The full solution
must work transparently in all useful list-type things:

    for my $item ( @iter )
    map { ... } @iter
    grep { ... } @iter
    sort { ... } @iter

=head1 TREATISE

=head2 Why A Core Iterator?

=over

=item while ( defined( my $i = $iter->() ) )

The current iterator pattern is unintuitive and requires a set of iterator-specific
functions to implement map, grep, and sort.

L<Iterator::Simple> is the best way of doing iterators available on CPAN, but
it requires a CPAN module and so can only do what CPAN modules can do. This
isn't itself a reason for adding a core iterator, but it should be considered.

=item A Better for ( <$fh> ) Pattern

New users often try to do a `for` loop over a filehandle and get confused when it
fails or performs poorly on very large files. Another pattern that must be learned:
C<while ( my $line = <$fh> )>.

An "iterable" filehandle would allow while and for to be treated equally.

=item Cannot be implemented on CPAN.

This module is an attempt to use C<tie> to make an array that had an iterator
underneath. It fails because tied arrays cannot be returned from subs, since
only lists are allowed to be returned from subs.

It would work with an arrayref, but this is not transparent, and as soon as the
array being referenced is given to C<map>, C<grep>, C<for>, C<sort>, or otherwise,
the array is reduced to a list, which will run the iterator until exhaustion.

Solving that problem doesn't make everything work, because an array must know
exactly how big they are before C<map> or C<grep> will work on them. See
t/iterator.t 'map iterator' for a failing test for this.  Since C<for> allows
modification of the array during iteration, tied arrays work just fine.

=back

=head2 Possible Syntax

=item Magic "iterable" flag on @array

If the magic flag is there, @array is really either a sub or a filehandle.

This is both the most magic and the least amount of user work.

=over

=item use feature qw( iterator ); my @iter = iterator { };

@array is now backed by an iterator.

C<gather> is not used as the function name because we are not implementing
C<take>.

=item use feature qw( iterator ); my @iter = iterator $fh;

If the C<iterator> gets a C<GLOB> or L<IO::Handle>, it does the right thing.

In fact, most of L<Iterator::Simple>'s functionality could work this way.

=item open my @fh, '<', 'FILENAME'

@fh is now an iterable filehandle according to C<$/> at the time of reading
the next line.

This is currently allowed (is not a syntax error), and under C<no strict "refs">
creates a filehandle called "0".

=back

=item <@array>

This is already used as a glob() operation, so this would be a backwards-
incompatible change. Evil.

=item @&array or &@array

The first one is a syntax error currently. The second can sometimes be
interpreted as bitwise-C<& @array>.

=back

=head2 Difficulties

=over

=item *

XS code that works with arrays may need to handle iterables differently,
especially with the magic version.

This would break the abstraction quite impressively, and a leaky abstraction
is frequently worse than no abstraction at all...

=back


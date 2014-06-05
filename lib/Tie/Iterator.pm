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


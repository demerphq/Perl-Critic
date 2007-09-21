##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Utils::McCabe;

use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :data_conversion :classification };

use base 'Exporter';

#-----------------------------------------------------------------------------

our $VERSION = 1.078;

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK =>
  qw( calculate_mccabe_of_sub calculate_mccabe_of_main );

#-----------------------------------------------------------------------------

Readonly::Hash my %LOGIC_OPS =>
    hashify( qw( && || ||= &&= or and xor ? <<= >>= ) );

Readonly::Hash my %LOGIC_KEYWORDS =>
    hashify( qw( if else elsif unless until while for foreach ) );

#-----------------------------------------------------------------------------

sub calculate_mccabe_of_sub {

    my ( $sub ) = @_;

    my $count = 1; # Minimum score is 1
    $count += _count_logic_keywords( $sub );
    $count += _count_logic_operators( $sub );

    return $count;
}

#-----------------------------------------------------------------------------

sub calculate_mccabe_of_main {

    my ( $doc ) = @_;

    my $count = 1; # Minimum score is 1
    $count += _count_main_logic_operators_and_keywords( $doc );
    return $count;
}

#-----------------------------------------------------------------------------

sub _count_main_logic_operators_and_keywords {

    my ( $doc ) = @_;

    # I can't leverage Perl::Critic::Document's fast search mechanism here
    # because we're not searching for elements by class name.  So to speed
    # things up, search for both keywords and operators at the same time.

    my $wanted = sub {

        my (undef, $elem) = @_;

        # Only count things that *are not* in a subroutine.  Returning an
        # explicit 'undef' here prevents PPI from descending into the node.

        ## no critic Subroutines::ProhibitExplicitReturnUndef
        return undef if $elem->isa('PPI::Statement::Sub');


        if ( $elem->isa('PPI::Token::Word') ) {
            return 0 if is_hash_key( $elem );
            return exists $LOGIC_KEYWORDS{$elem};
        }
        elsif ($elem->isa('PPI::Token::Operator') ) {
            return exists $LOGIC_OPS{$elem};
        }
    };

    my $logic_operators_and_keywords = $doc->find( $wanted );

    my $count = $logic_operators_and_keywords ?
      scalar @{$logic_operators_and_keywords} : 0;

    return $count;
}

#-----------------------------------------------------------------------------

sub _count_logic_keywords {

    my ( $sub ) = @_;
    my $count = 0;

    # Here, I'm using this round-about method of finding elements so
    # that I can take advantage of Perl::Critic::Document's faster
    # find() mechanism.  It can only search for elements by class name.

    my $keywords_ref = $sub->find('PPI::Token::Word');
    if ( $keywords_ref ) { # should always be true due to "sub" keyword
        my @filtered = grep { ! is_hash_key($_) } @{ $keywords_ref };
        $count = grep { exists $LOGIC_KEYWORDS{$_} } @filtered;
    }
    return $count;
}

#-----------------------------------------------------------------------------

sub _count_logic_operators {

    my ( $sub ) = @_;
    my $count = 0;

    # Here, I'm using this round-about method of finding elements so
    # that I can take advantage of Perl::Critic::Document's faster
    # find() mechanism.  It can only search for elements by class name.

    my $operators_ref = $sub->find('PPI::Token::Operator');
    if ( $operators_ref ) {
        $count = grep { exists $LOGIC_OPS{$_} }  @{ $operators_ref };
    }

    return $count;
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords McCabe

=head1 NAME

Perl::Critic::Utils::McCabe - Functions that calculate the McCabe score of source code.

=head1 DESCRIPTION

Provides approximations of McCabe scores.  The McCabe score of a set
of code describes the number of possible paths through it.  The
functions here approximate the McCabe score by summing the number of
conditional statements and operators within a set of code.  See
L<http://www.sei.cmu.edu/str/descriptions/cyclomatic_body.html> for
some discussion about the McCabe number and other complexity metrics.


=head1 IMPORTABLE SUBS

=over

=item C<calculate_mccabe_of_sub( $sub )>

Calculates an approximation of the McCabe number of the code in a
L<PPI::Statement::Sub>.

=item C<calculate_mccabe_of_main( $doc )>

Calculates an approximation of the McCabe number of all the code in a
L<PPI::Statement::Document> that is B<not> contained in a subroutine.

=back


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2007 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
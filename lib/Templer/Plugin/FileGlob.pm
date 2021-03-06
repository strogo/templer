
=head1 NAME

Templer::Plugin::FileGlob - A plugin to expand file globs.

=cut

=head1 SYNOPSIS

The following is a good example use of this plugin

  title: Images of cats
  images: file_glob( img/candid*.jpg )
  ----
  <li>
  <!-- tmpl_loop name='images' -->
    <li><img src="<!-- tmpl_var name='file' -->" width="<!-- tmpl_var name='width' -->" height="<!-- tmpl_var name='height' -->"  alt="Animal &amp; Pet Photography, Edinburgh" /></li>
  <!-- /tmpl_loop -->
  </ul>

=cut

=head1 DESCRIPTION

This plugin operates on file-patterns and populates loops refering
to the specified pattern.

The intended use-case is inline-gallery generation, but more uses
would surely be discovered.

=cut

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version,
or

b) the Perl "Artistic License".

=cut

=head1 AUTHOR

Steve Kemp <steve@steve.org.uk>

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013 Steve Kemp <steve@steve.org.uk>.

This library is free software. You can modify and or distribute it under
the same terms as Perl itself.

=cut

=head1 METHODS

=cut


use strict;
use warnings;


package Templer::Plugin::FileGlob;

use Cwd;


=head2

Constructor.  No arguments are required/supported.

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};
    bless( $self, $class );
    return $self;
}



=head2 expand_variables

This is the method which is called by the L<Templer::Plugin::Factory>
to expand the variables contained in a L<Templer::Site::Page> object.

Variables are written in the file in the form "key: value", and are
internally stored within the Page object as a hash.

This method iterates over each key & value and updates any that
seem to refer to file-globs.

=cut

sub expand_variables
{
    my ( $self, $site, $page, $data ) = (@_);

    #
    #  Get the page-variables in the template.
    #
    my %hash = %$data;

    #
    #  Look for a value of "file_glob" in each key.
    #
    foreach my $key ( keys %hash )
    {
        if ( $hash{ $key } =~ /^file_glob\((.*)\)/ )
        {

            #
            #  Populate an array of hash-refs referring to files which match
            #  a particular glob.
            #
            #  Could be used for many things, will be used for image-gallaries.
            #

            #
            #  Get the pattern and strip leading/trailing quotes and whitespace.
            #
            my $pattern = $1;
            $pattern =~ s/['"]//g;
            $pattern =~ s/^\s+|\s+$//g;

            #
            #  Make sure we're relative to the directory containing
            # the actual input-page.
            #
            #  This way globs will match what the author expected.
            #
            my $dirName = $page->source();
            if ( $dirName =~ /^(.*)\/(.*)$/ )
            {
                $dirName = $1;
            }
            my $pwd = Cwd::cwd();
            chdir( $dirName . "/" );

            #
            #  The value we'll set the variable to.
            #
            my $ref;


            #
            #  Run the glob.
            #
            foreach my $img ( glob($pattern) )
            {

                #
                # Data reference - moved here so we can add height/width if the
                # glob refers to an image, and if we have Image::Size installed.
                #
                my %meta = ( file => $img );

                #
                # If the file is an image AND we have Image::Size
                # then populate the height/width too.
                #
                if ( $img =~ /\.(jpe?g|png|gif)$/i )
                {
                    my $module = "use Image::Size;";
                    ## no critic (Eval)
                    eval($module);
                    ## use critic
                    if ( !$@ )
                    {
                        ( $meta{ 'width' }, $meta{ 'height' } ) =
                          imgsize( $dirName . "/" . $img );
                    }
                }
                push( @$ref, \%meta );
            }

            #
            #  If we found at least one file then we'll update
            # the variable value to refer to the populated structure.
            #
            if ($ref)
            {
                $hash{ $key } = $ref;
            }
            else
            {
                print
                  "WARNING: pattern '$pattern' matched zero files for page " .
                  $page->source() . "\n";
                delete $hash{ $key };
            }

            #
            #  Restore the PWD.
            #
            chdir($pwd);
        }
    }

    return ( \%hash );
}


#
#  Register the plugin.
#
Templer::Plugin::Factory->new()->register_plugin("Templer::Plugin::FileGlob");


#
# This class encapsulates a site.
#
# A site is comprised of "pages" and "assets".
#
# =over 8
#
# =item Pages
#
# Pages are things which are template expanded.
#
# =item Assets
#
# Assets are files that are merely copied from the input directory to
# the output path.  If we're running in "in-place" mode then they are
# ignored.
#
# =back
#
# This class contains helpers for finding and returning arrays of
# both such objects.
#
package Templer::Site;



#
# Constructor
#
sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    #
    #  Allow user supplied values to override our defaults
    #
    foreach my $key ( keys %supplied )
    {
        $self->{ lc $key } = $supplied{ $key };
    }

    bless( $self, $class );
    return $self;
}


#
# A site comprises of a collection of pages and a collection of static resources
# which aren't touched/modified - these are "assets".
#
# Return an object for each page we've found.
#
# NOTE: We don't process pages with a "." prefix, i.e. dotfiles.
#
sub pages
{
    my ( $self, %args ) = (@_);

    my $dir    = $args{ 'directory' } || $self->{ 'directory' };
    my $suffix = $args{ 'suffix' }    || $self->{ 'suffix' };

    return (
             $self->_findFiles( must_match    => $suffix . "\$",
                                object        => "Templer::Site::Page",
                                directory     => $dir,
                                hide_dotfiles => 1,
                              ) );
}


#
# A site comprises of a collection of pages and a collection of static resources
# which aren't touched/modified - these are "assets".
#
# Return an object for each asset we find.
#
# NOTE:  That we will include files which have a "." prefix here - to correctly
# copy files such as:
#
#    .htpasswd
#    .htaccess
#
sub assets
{
    my ( $self, %args ) = (@_);

    my $dir    = $args{ 'directory' } || $self->{ 'directory' };
    my $suffix = $args{ 'suffix' }    || $self->{ 'suffix' };

    return (
             $self->_findFiles( must_not_match => $suffix . "\$",
                                object         => "Templer::Site::Asset",
                                directory      => $dir,
                                hide_dotfiles  => 0,
                              ) );

}


#
# Find files beneath the given directory and return a new object
# for each one.
#
# We assume that the object constructor receives a hash as its sole
# argument with the key "file" containing the file path.
#
sub _findFiles
{
    my ( $self, %args ) = (@_);

    #
    # Remove the trailing "/" on the end of the directory to search.
    #
    $args{ 'directory' } =~ s/\/$//g;

    #
    # Should we hide dotfiles?
    #
    my $dotfiles = $args{ 'hide_dotfiles' };


    #
    #  Files we've found.  Ignoring the suffix just now.
    #
    my %files;

    File::Find::find( {
           wanted => sub {
               my $name = $File::Find::name;
               $files{ $name } += 1 unless ( $dotfiles && ( $name =~ /\/\./ ) );
           },
           follow      => 1,
           follow_skip => 2,
           no_chdir    => 1
        },
        $args{ 'directory' } );

    #
    # Remove the input
    #
    delete $files{ $args{ 'directory' } };

    #
    #  OK now we need to find the matches.
    #
    my @matches;

    #
    #  The class-object we're going to construct.
    #
    my $class = $args{ 'object' };

    if ( $args{ 'must_match' } )
    {
        foreach my $file ( sort keys %files )
        {
            next unless ( $file =~ /$args{'must_match'}/ );
            push( @matches, $class->new( file => $file ) );
        }
    }
    elsif ( $args{ 'must_not_match' } )
    {
        foreach my $file ( sort keys %files )
        {
            next if ( $file =~ /$args{'must_not_match'}/ );
            push( @matches, $class->new( file => $file ) );
        }
    }

    @matches;
}


1;

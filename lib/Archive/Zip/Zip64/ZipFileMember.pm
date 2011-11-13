package Archive::Zip::Zip64::ZipFileMember;

# Represents a generic ZIP64 archive

use strict;
use warnings;
use Math::BigInt;

use vars qw( $VERSION @ISA );

BEGIN {
    $VERSION = '1.31_02';
    @ISA     = qw( Archive::Zip::ZipFileMember );
}

use Archive::Zip qw(
  :CONSTANTS
  :ERROR_CODES
  :PKZIP_CONSTANTS
  :UTILITY_METHODS
);

sub compressedSize {
    shift->{'zip64CompressedSize'};
}

sub uncompressedSize {
    shift->{'zip64UncompressedSize'};
}

sub localHeaderRelativeOffset {
    shift->{'zip64LocalHeaderRelativeOffset'};
}

sub _readZip64ExtraField {
    my $self = shift;
    my $fieldData = shift;

    my ($us_h, $us_l);
    my ($cs_h, $cs_l);
    my ($offset_h, $offset_l);
    (
      $us_h,
      $us_l,
      $cs_h,
      $cs_l,
      $offset_h,
      $offset_l,
      $self->{'zip64DiskNumberStart'}
    ) = unpack( ZIP64_EXTRA_FIELD_FORMAT, $fieldData);
    
    $self->{'zip64UncompressedSize'} = _partsToBigint($us_h, $us_l);
    $self->{'zip64CompressedSize'} = _partsToBigint($cs_h, $cs_l);
    $self->{'zip64LocalHeaderRelativeOffset'} = _partsToBigint($offset_h, $offset_l);
}

1;

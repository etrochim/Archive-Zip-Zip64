package Archive::Zip::Zip64::Archive;

# Represents a generic ZIP64 archive

use strict;
use warnings;

use vars qw( $VERSION @ISA );

BEGIN {
    $VERSION = '1.31_02';
    @ISA     = qw( Archive::Zip::Archive );
}

use Archive::Zip qw(
  :CONSTANTS
  :ERROR_CODES
  :PKZIP_CONSTANTS
  :UTILITY_METHODS
);

sub centralDirectorySize {
    shift->{'zip64CentralDirectorySize'};
}

sub centralDirectoryOffsetWRTStartingDiskNumber {
    shift->{'zip64CentralDirectoryOffsetWRTStartingDiskNumber'};
}

sub zip64SizeOfEndOfCentralDirectory {
    shift->{'zip64SizeOfEndOfCentralDirectory'};
}

sub zip64EndOfCentralDirectoryRelativeOffset {
    shift->{'zip64EndOfCentralDirectoryRelativeOffset'};
}

sub _readZip64EndOfCentralDirectory {
    my $self = shift;
    my $fh = shift;

    my $signatureData;
    $fh->read( $signatureData, SIGNATURE_LENGTH )
      or return _ioError("reading zip64 end of central directory signature");
    my $signature = unpack( SIGNATURE_FORMAT, $signatureData );
    if( $signature != ZIP64_END_OF_CENTRAL_DIRECTORY_SIGNATURE ) {
        return _formatError("zip64 eocd signature not found");
    }
      
    my $header = '';
    my $bytesRead = $fh->read( $header, ZIP64_END_OF_CENTRAL_DIRECTORY_LENGTH ); 
    if( $bytesRead != ZIP64_END_OF_CENTRAL_DIRECTORY_LENGTH ) {
        return _ioError("reading zip64 end of central directory");
    }
    
    my ($size_l, $size_h);
    my ($entry_number_disk_l, $entry_number_disk_h);
    my ($entry_number_l, $entry_number_h);
    my ($offset_l, $offset_h);
    my ($cd_size_l, $cd_size_h);
    (
        $size_h,
        $size_l,
        $self->{'zip64VersionMakeBy'},
        $self->{'zip64VersionNeededToExtract'},
        $self->{'zip64DiskNumber'},
        $self->{'zip64DiskNumberWithStartOfCentralDirectory'},
        $entry_number_disk_h,
        $entry_number_disk_l,
        $entry_number_h,
        $entry_number_l,
        $cd_size_h,
        $cd_size_l,
        $offset_h,
        $offset_l
    ) = unpack( ZIP64_END_OF_CENTRAL_DIRECTORY_FORMAT, $header );

    $self->{'zip64SizeOfEndOfCentralDirectory'} = _partsToBigint($size_h, $size_l);
    $self->{'zip64CentralDirectoryOffsetWRTStartingDiskNumber'} = _partsToBigint($entry_number_disk_h, $entry_number_disk_l);
    $self->{'zip64NumberOfCentralDirectories'} = _partsToBigint($entry_number_h, $entry_number_l);
    $self->{'zip64CentralDirectorySize'} = _partsToBigint($cd_size_h, $cd_size_l);
    $self->{'zip64CentralDirectoryOffsetWRTStartingDiskNumber'} = _partsToBigint($offset_h, $offset_l);

    # The length of the Zip64 Extensible data is however many bytes are left in the
    # Zip64 End of Central Directory that we haven't yet read. However, the 
    # zip64SizeOfEndOfCentralDirectory field doesn't count the size of itself,
    # so we need to subtract that length off.
    my $z64ExtensibleDataSize =
      $self->{'zip64SizeOfEndOfCentralDirectory'} - ( ZIP64_END_OF_CENTRAL_DIRECTORY_LENGTH - 8 );

    $bytesRead = $fh->read( $self->{'zip64ExtensibleData'}, $z64ExtensibleDataSize );
    if( $bytesRead != $z64ExtensibleDataSize ) {
      return _ioError("reading zip64 extensible data");
    }

    return AZ_OK;
}

sub _readZip64EndOfCentralDirectoryLocator {
    my $self = shift;
    my $fh   = shift;

    my $header = '';
    my $bytesRead = $fh->read( $header, ZIP64_END_OF_CENTRAL_DIRECTORY_LOCATOR_LENGTH );
    if ( $bytesRead != ZIP64_END_OF_CENTRAL_DIRECTORY_LOCATOR_LENGTH ) {
        return _ioError("reading zip64 end of central directory locator");
    }

    my ($relative_offset_h, $relative_offset_l);
    (
        $self->{'diskNumberWithStartOfZip64CentralDirectoryLocator'},
        $relative_offset_h,
        $relative_offset_l,
        $self->{'totalNumberOfDisks'},
    ) = unpack( ZIP64_END_OF_CENTRAL_DIRECTORY_LOCATOR_FORMAT, $header );

    $self->{'zip64EndOfCentralDirectoryRelativeOffset'} = _partsToBigint($relative_offset_h, $relative_offset_l);

    return AZ_OK;
}

1;

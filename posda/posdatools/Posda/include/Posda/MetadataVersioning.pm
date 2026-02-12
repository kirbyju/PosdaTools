#!/usr/bin/perl -w
#
# Copyright 2024, Bill Bennett
# Part of the Posda package
# Posda may be copied only under the terms of either the Artistic License or the
# GNU General Public License, which may be found in the Posda Distribution,
# or at http://posda.com/License.html
#
# Module: Posda::MetadataVersioning
# Purpose: Provide storage-efficient metadata versioning for DICOM files
#          by tracking metadata changes without duplicating pixel data
#
use strict;
package Posda::MetadataVersioning;
use Posda::DB 'Query';
use Posda::Dataset;
use Digest::MD5;

=head1 NAME

Posda::MetadataVersioning - Storage-efficient DICOM metadata versioning

=head1 SYNOPSIS

  use Posda::MetadataVersioning;
  
  # Check if an edit is metadata-only
  my $is_metadata_only = Posda::MetadataVersioning::IsMetadataOnlyEdit(
    $original_dataset, $modified_dataset
  );
  
  # Log metadata changes
  Posda::MetadataVersioning::LogMetadataChanges(
    $edit_event_id, $from_digest, $to_digest, $base_digest, \@changes
  );
  
  # Get pixel data info from a dataset
  my $pixel_info = Posda::MetadataVersioning::GetPixelDataInfo($dataset);

=head1 DESCRIPTION

This module provides functionality to implement storage-efficient metadata
versioning for DICOM files. When a DICOM file is edited and only metadata
changes (not pixel data), the system can log the metadata changes without
duplicating the pixel data, significantly reducing storage requirements.

=cut

=head2 IsMetadataOnlyEdit

Determines if an edit only modified metadata (not pixel data).

  my $is_metadata_only = IsMetadataOnlyEdit($original_ds, $modified_ds);

Returns 1 if only metadata changed, 0 if pixel data changed.

=cut

sub IsMetadataOnlyEdit {
  my($original_ds, $modified_ds) = @_;
  
  # Get pixel data from both datasets
  my $orig_pixel = $original_ds->Get("(7fe0,0010)");
  my $mod_pixel = $modified_ds->Get("(7fe0,0010)");
  
  # If one has pixel data and the other doesn't, it's not metadata-only
  if (defined($orig_pixel) != defined($mod_pixel)) {
    return 0;
  }
  
  # If neither has pixel data, it's metadata-only
  if (!defined($orig_pixel) && !defined($mod_pixel)) {
    return 1;
  }
  
  # Compare pixel data digests
  my $orig_pixel_digest = _ComputePixelDataDigest($orig_pixel);
  my $mod_pixel_digest = _ComputePixelDataDigest($mod_pixel);
  
  # If digests match, pixel data is unchanged
  return ($orig_pixel_digest eq $mod_pixel_digest) ? 1 : 0;
}

=head2 GetPixelDataInfo

Extracts pixel data information from a dataset.

  my $info = GetPixelDataInfo($dataset);

Returns a hashref with:
  - has_pixel_data: boolean
  - pixel_data_digest: MD5 digest of pixel data
  - pixel_data_offset: offset in file (if known)
  - pixel_data_length: length of pixel data

=cut

sub GetPixelDataInfo {
  my($ds) = @_;
  
  my $pixel_data = $ds->Get("(7fe0,0010)");
  
  if (!defined($pixel_data)) {
    return {
      has_pixel_data => 0,
      pixel_data_digest => undef,
      pixel_data_offset => undef,
      pixel_data_length => undef,
    };
  }
  
  my $digest = _ComputePixelDataDigest($pixel_data);
  my $length = _GetPixelDataLength($pixel_data);
  
  return {
    has_pixel_data => 1,
    pixel_data_digest => $digest,
    pixel_data_offset => undef,  # Would need to be extracted from file parse
    pixel_data_length => $length,
  };
}

=head2 CompareMetadata

Compares two datasets and returns a list of metadata changes.

  my @changes = CompareMetadata($original_ds, $modified_ds);

Each change is a hashref with:
  - tag_signature: e.g., "(0010,0010)"
  - tag_name: human-readable name
  - old_value: previous value
  - new_value: new value
  - operation: 'modify', 'delete', or 'insert'

=cut

sub CompareMetadata {
  my($original_ds, $modified_ds) = @_;
  my @changes;
  
  # Get all tags from both datasets (excluding pixel data)
  my %orig_tags = _GetAllTags($original_ds);
  my %mod_tags = _GetAllTags($modified_ds);
  
  # Find modified and deleted tags
  for my $tag (keys %orig_tags) {
    next if $tag eq "(7fe0,0010)";  # Skip pixel data
    
    if (exists $mod_tags{$tag}) {
      # Tag exists in both - check if modified
      if ($orig_tags{$tag} ne $mod_tags{$tag}) {
        push @changes, {
          tag_signature => $tag,
          tag_name => _GetTagName($tag),
          old_value => $orig_tags{$tag},
          new_value => $mod_tags{$tag},
          operation => 'modify',
        };
      }
    } else {
      # Tag deleted
      push @changes, {
        tag_signature => $tag,
        tag_name => _GetTagName($tag),
        old_value => $orig_tags{$tag},
        new_value => undef,
        operation => 'delete',
      };
    }
  }
  
  # Find inserted tags
  for my $tag (keys %mod_tags) {
    next if $tag eq "(7fe0,0010)";  # Skip pixel data
    
    if (!exists $orig_tags{$tag}) {
      push @changes, {
        tag_signature => $tag,
        tag_name => _GetTagName($tag),
        old_value => undef,
        new_value => $mod_tags{$tag},
        operation => 'insert',
      };
    }
  }
  
  return @changes;
}

=head2 LogMetadataChanges

Logs metadata changes to the database.

  LogMetadataChanges($edit_event_id, $from_digest, $to_digest, 
                     $base_digest, \@changes);

=cut

sub LogMetadataChanges {
  my($edit_event_id, $from_digest, $to_digest, $base_digest, $changes_ref) = @_;
  
  my $insert_query = Query('InsertMetadataChange');
  
  for my $change (@$changes_ref) {
    eval {
      $insert_query->execute(
        dicom_edit_event_id => $edit_event_id,
        from_file_digest => $from_digest,
        to_file_digest => $to_digest,
        base_file_digest => $base_digest,
        tag_signature => $change->{tag_signature},
        tag_name => $change->{tag_name},
        old_value => $change->{old_value},
        new_value => $change->{new_value},
        operation_type => $change->{operation},
        pixel_data_shared => 1,
      );
    };
    if ($@) {
      warn "Failed to log metadata change for tag $change->{tag_signature}: $@";
    }
  }
}

=head2 LogSharedPixelData

Records that a file shares pixel data with another file.

  LogSharedPixelData($pixel_digest, $base_digest, $derived_digest, 
                     $offset, $length);

=cut

sub LogSharedPixelData {
  my($pixel_digest, $base_digest, $derived_digest, $offset, $length) = @_;
  
  my $insert_query = Query('InsertSharedPixelData');
  
  eval {
    $insert_query->execute(
      pixel_data_digest => $pixel_digest,
      base_file_digest => $base_digest,
      derived_file_digest => $derived_digest,
      pixel_data_offset => $offset,
      pixel_data_length => $length,
    );
  };
  if ($@) {
    warn "Failed to log shared pixel data: $@";
  }
}

=head2 UpdateEditMetadataOnlyFlag

Updates the dicom_file_edit table to mark an edit as metadata-only.

  UpdateEditMetadataOnlyFlag($edit_event_id, $from_digest, $to_digest, 
                             $bytes_saved);

=cut

sub UpdateEditMetadataOnlyFlag {
  my($edit_event_id, $from_digest, $to_digest, $bytes_saved) = @_;
  
  my $update_query = Query('UpdateMetadataOnlyEdit');
  
  eval {
    $update_query->execute(
      dicom_edit_event_id => $edit_event_id,
      from_file_digest => $from_digest,
      to_file_digest => $to_digest,
      storage_bytes_saved => $bytes_saved,
    );
  };
  if ($@) {
    warn "Failed to update metadata-only flag: $@";
  }
}

#
# Private helper functions
#

sub _ComputePixelDataDigest {
  my($pixel_data) = @_;
  
  if (ref($pixel_data) eq "ARRAY") {
    # Compressed/encapsulated pixel data
    my $all_data = join("", @$pixel_data);
    return Digest::MD5::md5_hex($all_data);
  } else {
    # Uncompressed pixel data
    return Digest::MD5::md5_hex($pixel_data);
  }
}

sub _GetPixelDataLength {
  my($pixel_data) = @_;
  
  if (ref($pixel_data) eq "ARRAY") {
    # Compressed/encapsulated pixel data
    my $total = 0;
    for my $fragment (@$pixel_data) {
      $total += length($fragment);
    }
    return $total;
  } else {
    # Uncompressed pixel data
    return length($pixel_data);
  }
}

sub _GetAllTags {
  my($ds) = @_;
  my %tags;
  
  # Iterate through all groups in the dataset
  for my $grp (keys %$ds) {
    next unless ref($ds->{$grp}) eq "HASH";
    
    for my $ele (keys %{$ds->{$grp}}) {
      next if $ele eq "private";  # Skip private tag structure
      next unless ref($ds->{$grp}->{$ele}) eq "HASH";
      
      my $tag_sig = sprintf("(%04x,%04x)", $grp, $ele);
      my $value = $ds->Get($tag_sig);
      
      if (defined($value)) {
        # Convert value to string representation
        if (ref($value) eq "ARRAY") {
          $tags{$tag_sig} = join("\\", @$value);
        } else {
          $tags{$tag_sig} = $value;
        }
      }
    }
  }
  
  return %tags;
}

sub _GetTagName {
  my($tag_sig) = @_;
  
  # Try to get tag name from data dictionary
  # For now, return the signature as the name
  # This could be enhanced to use Posda::DataDict
  return $tag_sig;
}

1;

__END__

=head1 AUTHOR

Posda Development Team

=head1 COPYRIGHT

Copyright 2024, Bill Bennett

=head1 LICENSE

This program may be copied only under the terms of either the Artistic License 
or the GNU General Public License, which may be found in the Posda Distribution,
or at http://posda.com/License.html

=cut

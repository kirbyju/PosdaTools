#!/usr/bin/perl -w
#
# Demo script showing how to use the Posda::MetadataVersioning module
# This script demonstrates the storage-efficient metadata versioning system
#
# Note: This is a demonstration script that simulates the behavior without
# requiring a full Posda environment. In production, you would use the actual
# Posda::Dataset and Posda::MetadataVersioning modules.
#
use strict;

print "=" x 80 . "\n";
print "DICOM Metadata Versioning Demo\n";
print "=" x 80 . "\n\n";

print <<'EOF';
This demo shows how the new metadata versioning system works:

1. Detects metadata-only edits (vs pixel data changes)
2. Logs individual metadata field changes
3. Tracks shared pixel data between file versions
4. Calculates storage savings

The system is designed to maximize storage efficiency by avoiding
duplication of pixel data when only metadata is modified.

EOF

# Simulate loading two datasets (original and modified)
print "Step 1: Conceptual Overview\n";
print "-" x 80 . "\n";

# In a real scenario, datasets would be loaded from actual DICOM files:
# use Posda::Dataset;
# my $original_ds = Posda::Dataset->new("original_file.dcm");
# my $modified_ds = Posda::Dataset->new("modified_file.dcm");

print "Loading datasets (simulated)...\n";
print "Original Dataset:\n";
print "  Patient Name: Doe^John\n";
print "  Patient ID: 12345\n";
print "  Study Date: 20240101\n";
print "  Pixel Data: <50 MB of pixel data>\n\n";

print "Modified Dataset:\n";
print "  Patient Name: Anonymous  (CHANGED)\n";
print "  Patient ID: ANON001      (CHANGED)\n";
print "  Study Date: 20240601     (CHANGED)\n";
print "  Pixel Data: <50 MB of pixel data> (UNCHANGED)\n\n";

# Step 2: Check if metadata-only edit
print "Step 2: Checking if edit is metadata-only\n";
print "-" x 80 . "\n";

# In a real scenario with actual pixel data:
# my $is_metadata_only = Posda::MetadataVersioning::IsMetadataOnlyEdit(
#     $original_ds, $modified_ds
# );

# For demo purposes, we simulate this
my $is_metadata_only = 1;  # Simulated result

if ($is_metadata_only) {
    print "✓ Detected: Metadata-only edit\n";
    print "  Pixel data digest matches between original and modified files\n";
    print "  No pixel data duplication needed!\n\n";
} else {
    print "✗ Pixel data changed\n";
    print "  Full file copy required\n\n";
}

# Step 3: Get pixel data info
print "Step 3: Getting pixel data information\n";
print "-" x 80 . "\n";

# my $pixel_info = Posda::MetadataVersioning::GetPixelDataInfo($original_ds);

# Simulated pixel info
my $pixel_info = {
    has_pixel_data => 1,
    pixel_data_digest => "abc123def456789...",
    pixel_data_offset => 2048,
    pixel_data_length => 52428800,  # 50 MB
};

print "Pixel Data Info:\n";
print "  Has Pixel Data: " . ($pixel_info->{has_pixel_data} ? "Yes" : "No") . "\n";
print "  Digest: $pixel_info->{pixel_data_digest}\n";
print "  Offset: $pixel_info->{pixel_data_offset} bytes\n";
print "  Length: " . format_bytes($pixel_info->{pixel_data_length}) . "\n\n";

# Step 4: Compare metadata
print "Step 4: Comparing metadata between files\n";
print "-" x 80 . "\n";

# my @changes = Posda::MetadataVersioning::CompareMetadata(
#     $original_ds, $modified_ds
# );

# Simulated changes
my @changes = (
    {
        tag_signature => "(0010,0010)",
        tag_name => "Patient Name",
        old_value => "Doe^John",
        new_value => "Anonymous",
        operation => "modify",
    },
    {
        tag_signature => "(0010,0020)",
        tag_name => "Patient ID",
        old_value => "12345",
        new_value => "ANON001",
        operation => "modify",
    },
    {
        tag_signature => "(0008,0020)",
        tag_name => "Study Date",
        old_value => "20240101",
        new_value => "20240601",
        operation => "modify",
    },
);

print "Metadata Changes Detected:\n";
for my $change (@changes) {
    print "\n";
    print "  Tag: $change->{tag_signature} ($change->{tag_name})\n";
    print "  Operation: $change->{operation}\n";
    print "  Old Value: $change->{old_value}\n";
    print "  New Value: $change->{new_value}\n";
}
print "\n";

# Step 5: Calculate storage savings
print "Step 5: Calculating storage savings\n";
print "-" x 80 . "\n";

my $original_file_size = 52430000;  # ~50 MB
my $metadata_log_size = scalar(@changes) * 500;  # ~500 bytes per change
my $bytes_saved = $pixel_info->{pixel_data_length};

print "Storage Analysis:\n";
print "  Original File Size: " . format_bytes($original_file_size) . "\n";
print "  Pixel Data Size: " . format_bytes($pixel_info->{pixel_data_length}) . "\n";
print "  Metadata Log Size: " . format_bytes($metadata_log_size) . "\n";
print "\n";
print "  Old Approach (full file copy):\n";
print "    Storage Used: " . format_bytes($original_file_size) . "\n";
print "\n";
print "  New Approach (metadata log):\n";
print "    Storage Used: " . format_bytes($metadata_log_size) . "\n";
print "    Storage Saved: " . format_bytes($bytes_saved) . "\n";
print "    Savings Percentage: " . 
    sprintf("%.3f%%", ($bytes_saved / $original_file_size) * 100) . "\n";
print "\n";

# Step 6: Demonstrate database logging (simulated)
print "Step 6: Logging to database (simulated)\n";
print "-" x 80 . "\n";

my $edit_event_id = 12345;
my $from_digest = "original_file_digest_abc123";
my $to_digest = "modified_file_digest_xyz789";

print "Database Operations:\n";
print "  1. Log metadata changes to dicom_metadata_change_log\n";
print "     - Edit Event ID: $edit_event_id\n";
print "     - From Digest: $from_digest\n";
print "     - To Digest: $to_digest\n";
print "     - Changes: " . scalar(@changes) . " field modifications\n";
print "\n";
print "  2. Record shared pixel data in dicom_shared_pixel_data\n";
print "     - Pixel Digest: $pixel_info->{pixel_data_digest}\n";
print "     - Base File: $from_digest\n";
print "     - Derived File: $to_digest\n";
print "\n";
print "  3. Update dicom_file_edit table\n";
print "     - Set metadata_only_edit = true\n";
print "     - Set storage_bytes_saved = $bytes_saved\n";
print "\n";

# Summary
print "=" x 80 . "\n";
print "SUMMARY\n";
print "=" x 80 . "\n\n";

print "The metadata versioning system successfully:\n";
print "  ✓ Detected a metadata-only edit (pixel data unchanged)\n";
print "  ✓ Logged ${\(scalar @changes)} metadata field changes\n";
print "  ✓ Avoided duplicating " . format_bytes($bytes_saved) . " of pixel data\n";
print "  ✓ Achieved " . sprintf("%.1f%%", ($bytes_saved / $original_file_size) * 100) . 
      " storage savings\n\n";

print "In a production environment with thousands of edits, this system can\n";
print "save terabytes of storage space while maintaining full audit trails.\n\n";

print "For more information, see docs/METADATA_VERSIONING.md\n";

# Helper function to format bytes
sub format_bytes {
    my ($bytes) = @_;
    return "0 bytes" if $bytes == 0;
    
    my @units = ('bytes', 'KB', 'MB', 'GB', 'TB');
    my $unit_index = 0;
    my $size = $bytes;
    
    while ($size >= 1024 && $unit_index < $#units) {
        $size /= 1024;
        $unit_index++;
    }
    
    return sprintf("%.2f %s", $size, $units[$unit_index]);
}

__END__

=head1 NAME

demo_metadata_versioning.pl - Demo script for DICOM metadata versioning

=head1 SYNOPSIS

  ./demo_metadata_versioning.pl

=head1 DESCRIPTION

This script demonstrates the new storage-efficient metadata versioning system
for DICOM files. It shows how the system:

1. Detects metadata-only edits
2. Logs individual field changes
3. Tracks shared pixel data
4. Calculates storage savings

=head1 AUTHOR

Posda Development Team

=head1 COPYRIGHT

Copyright 2024, Bill Bennett

=cut

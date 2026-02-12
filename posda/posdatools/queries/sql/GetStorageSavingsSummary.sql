-- Get summary of storage savings from metadata-only edits
SELECT 
  COUNT(*) as num_metadata_only_edits,
  SUM(storage_bytes_saved) as total_bytes_saved,
  SUM(storage_bytes_saved) / (1024.0 * 1024.0) as total_mb_saved,
  SUM(storage_bytes_saved) / (1024.0 * 1024.0 * 1024.0) as total_gb_saved
FROM dicom_file_edit
WHERE metadata_only_edit = true

-- Get all metadata changes for a specific file transformation
SELECT 
  change_log_id,
  dicom_edit_event_id,
  base_file_digest,
  tag_signature,
  tag_name,
  old_value,
  new_value,
  operation_type,
  change_timestamp,
  pixel_data_shared
FROM dicom_metadata_change_log
WHERE 
  from_file_digest = $<from_file_digest>
  AND to_file_digest = $<to_file_digest>
ORDER BY change_timestamp

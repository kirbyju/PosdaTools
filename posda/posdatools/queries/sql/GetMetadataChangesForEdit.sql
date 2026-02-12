-- Get all metadata changes for an edit event
SELECT 
  change_log_id,
  from_file_digest,
  to_file_digest,
  base_file_digest,
  tag_signature,
  tag_name,
  old_value,
  new_value,
  operation_type,
  change_timestamp,
  pixel_data_shared
FROM dicom_metadata_change_log
WHERE dicom_edit_event_id = $<dicom_edit_event_id>
ORDER BY change_timestamp

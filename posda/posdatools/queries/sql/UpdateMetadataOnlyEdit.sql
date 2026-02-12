-- Update dicom_file_edit to mark as metadata-only and record storage savings
UPDATE dicom_file_edit
SET 
  metadata_only_edit = true,
  storage_bytes_saved = $<storage_bytes_saved>
WHERE 
  dicom_edit_event_id = $<dicom_edit_event_id>
  AND from_file_digest = $<from_file_digest>
  AND to_file_digest = $<to_file_digest>

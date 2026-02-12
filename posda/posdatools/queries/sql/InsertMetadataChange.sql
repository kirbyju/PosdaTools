-- Insert a metadata change record
INSERT INTO dicom_metadata_change_log (
  dicom_edit_event_id,
  from_file_digest,
  to_file_digest,
  base_file_digest,
  tag_signature,
  tag_name,
  old_value,
  new_value,
  operation_type,
  pixel_data_shared
) VALUES (
  $<dicom_edit_event_id>,
  $<from_file_digest>,
  $<to_file_digest>,
  $<base_file_digest>,
  $<tag_signature>,
  $<tag_name>,
  $<old_value>,
  $<new_value>,
  $<operation_type>,
  $<pixel_data_shared>
)

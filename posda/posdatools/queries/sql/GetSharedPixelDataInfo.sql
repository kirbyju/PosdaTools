-- Get shared pixel data information for a derived file
SELECT 
  shared_pixel_id,
  pixel_data_digest,
  base_file_digest,
  pixel_data_offset,
  pixel_data_length,
  created_at
FROM dicom_shared_pixel_data
WHERE derived_file_digest = $<derived_file_digest>

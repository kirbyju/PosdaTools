-- Record that a file shares pixel data with another file
INSERT INTO dicom_shared_pixel_data (
  pixel_data_digest,
  base_file_digest,
  derived_file_digest,
  pixel_data_offset,
  pixel_data_length
) VALUES (
  $<pixel_data_digest>,
  $<base_file_digest>,
  $<derived_file_digest>,
  $<pixel_data_offset>,
  $<pixel_data_length>
)

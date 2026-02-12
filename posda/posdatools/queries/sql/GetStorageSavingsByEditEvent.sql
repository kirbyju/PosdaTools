-- Get storage savings by edit event
SELECT 
  dee.dicom_edit_event_id,
  dee.edit_comment,
  dee.time_started,
  dee.time_completed,
  COUNT(*) as num_files_edited,
  SUM(CASE WHEN dfe.metadata_only_edit THEN 1 ELSE 0 END) as num_metadata_only,
  SUM(dfe.storage_bytes_saved) as total_bytes_saved,
  SUM(dfe.storage_bytes_saved) / (1024.0 * 1024.0 * 1024.0) as total_gb_saved
FROM dicom_edit_event dee
JOIN dicom_file_edit dfe ON dee.dicom_edit_event_id = dfe.dicom_edit_event_id
WHERE dee.time_completed IS NOT NULL
GROUP BY dee.dicom_edit_event_id, dee.edit_comment, dee.time_started, dee.time_completed
ORDER BY dee.time_completed DESC
LIMIT $<limit>

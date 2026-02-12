-- Migration: Create metadata change log table for storage-efficient DICOM versioning
-- Purpose: Track individual metadata field changes instead of duplicating entire files
--          when only metadata is modified (pixel data remains unchanged)

-- Table to track individual metadata field changes
CREATE TABLE IF NOT EXISTS public.dicom_metadata_change_log (
    change_log_id SERIAL PRIMARY KEY,
    dicom_edit_event_id integer NOT NULL REFERENCES public.dicom_edit_event(dicom_edit_event_id),
    from_file_digest text NOT NULL,
    to_file_digest text NOT NULL,
    base_file_digest text NOT NULL,  -- The file containing the actual pixel data
    tag_signature text NOT NULL,     -- DICOM tag signature (e.g., "(0010,0010)")
    tag_name text,                   -- Human-readable tag name (e.g., "Patient Name")
    old_value text,                  -- Previous metadata value
    new_value text,                  -- New metadata value
    operation_type text NOT NULL,    -- Type of operation: 'modify', 'delete', 'insert'
    change_timestamp timestamp with time zone DEFAULT now(),
    pixel_data_shared boolean DEFAULT true  -- True if pixel data is shared with base file
);

-- Add indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_metadata_change_log_edit_event 
    ON public.dicom_metadata_change_log(dicom_edit_event_id);

CREATE INDEX IF NOT EXISTS idx_metadata_change_log_from_digest 
    ON public.dicom_metadata_change_log(from_file_digest);

CREATE INDEX IF NOT EXISTS idx_metadata_change_log_to_digest 
    ON public.dicom_metadata_change_log(to_file_digest);

CREATE INDEX IF NOT EXISTS idx_metadata_change_log_base_digest 
    ON public.dicom_metadata_change_log(base_file_digest);

CREATE INDEX IF NOT EXISTS idx_metadata_change_log_tag 
    ON public.dicom_metadata_change_log(tag_signature);

-- Table to track files that share pixel data
CREATE TABLE IF NOT EXISTS public.dicom_shared_pixel_data (
    shared_pixel_id SERIAL PRIMARY KEY,
    pixel_data_digest text NOT NULL,     -- Digest of the pixel data
    base_file_digest text NOT NULL,      -- Original file containing pixel data
    derived_file_digest text NOT NULL,   -- Derived file that references the pixel data
    pixel_data_offset integer NOT NULL,  -- Offset of pixel data in base file
    pixel_data_length integer NOT NULL,  -- Length of pixel data
    created_at timestamp with time zone DEFAULT now()
);

-- Add indexes for shared pixel data tracking
CREATE INDEX IF NOT EXISTS idx_shared_pixel_data_pixel_digest 
    ON public.dicom_shared_pixel_data(pixel_data_digest);

CREATE INDEX IF NOT EXISTS idx_shared_pixel_data_base_digest 
    ON public.dicom_shared_pixel_data(base_file_digest);

CREATE INDEX IF NOT EXISTS idx_shared_pixel_data_derived_digest 
    ON public.dicom_shared_pixel_data(derived_file_digest);

-- Add comment to document the purpose
COMMENT ON TABLE public.dicom_metadata_change_log IS 
    'Tracks individual metadata field changes to avoid duplicating pixel data when only metadata is modified';

COMMENT ON TABLE public.dicom_shared_pixel_data IS 
    'Tracks files that share the same pixel data, enabling storage deduplication';

-- Add column to dicom_file_edit to track if edit was metadata-only
ALTER TABLE public.dicom_file_edit 
    ADD COLUMN IF NOT EXISTS metadata_only_edit boolean DEFAULT false;

ALTER TABLE public.dicom_file_edit 
    ADD COLUMN IF NOT EXISTS storage_bytes_saved bigint DEFAULT 0;

COMMENT ON COLUMN public.dicom_file_edit.metadata_only_edit IS 
    'True if this edit only modified metadata, allowing pixel data sharing';

COMMENT ON COLUMN public.dicom_file_edit.storage_bytes_saved IS 
    'Number of bytes saved by not duplicating pixel data for metadata-only edits';

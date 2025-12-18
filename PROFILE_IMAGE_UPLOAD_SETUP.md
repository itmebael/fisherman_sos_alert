# Profile Image Upload Setup Guide

## Overview
Profile images are now uploaded to Supabase Storage and the URL is saved in the `profile_image_url` column of the `fishermen` table.

## Setup Instructions

### 1. Create Supabase Storage Bucket

1. Go to your Supabase Dashboard
2. Navigate to **Storage** section
3. Click **New bucket**
4. Create a bucket named: `profile-images`
5. Set it as **Public bucket** (so images can be accessed via URL)
6. Click **Create bucket**

### 2. Set Storage Policies (RLS)

Run this SQL in your Supabase SQL Editor:

```sql
-- Allow authenticated users to upload their own profile images
CREATE POLICY "Users can upload own profile images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-images' AND
  (storage.foldername(name))[1] = 'profiles'
);

-- Allow authenticated users to update their own profile images
CREATE POLICY "Users can update own profile images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-images' AND
  (storage.foldername(name))[1] = 'profiles'
);

-- Allow public read access to profile images
CREATE POLICY "Public can read profile images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-images');

-- Allow authenticated users to delete their own profile images
CREATE POLICY "Users can delete own profile images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-images' AND
  (storage.foldername(name))[1] = 'profiles'
);
```

### 3. Verify Database Column

Ensure the `profile_image_url` column exists in the `fishermen` table:

```sql
-- Check if column exists
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'fishermen' 
AND column_name = 'profile_image_url';

-- If it doesn't exist, add it:
ALTER TABLE public.fishermen 
ADD COLUMN IF NOT EXISTS profile_image_url TEXT NULL;
```

## How It Works

### Fisherman Registration
1. User selects profile image (camera/gallery)
2. Image is uploaded to Supabase Storage before account creation
3. Public URL is obtained
4. Account is created with `profile_image_url` field populated
5. URL is saved in the `fishermen` table

### Admin User Creation
1. Admin selects profile image for new user
2. Image is uploaded to Supabase Storage
3. Public URL is obtained
4. User account is created with `profile_image_url` field populated

### Image Upload Service
- **File**: `lib/services/image_upload_service.dart`
- **Features**:
  - Validates file size (max 5MB)
  - Validates file type (jpg, jpeg, png, webp)
  - Generates unique file names
  - Uploads with retry logic
  - Returns public URL

## File Structure in Storage

```
profile-images/
  └── profiles/
      └── {userId}_{timestamp}.{extension}
```

Example: `profiles/temp_user_example_com_1234567890.jpg`

## Testing

1. **Test Image Upload**:
   - Create a new fisherman account
   - Select a profile image
   - Verify image uploads successfully
   - Check that `profile_image_url` is saved in database

2. **Verify Image Display**:
   - Login as the fisherman
   - Go to profile screen
   - Verify profile image displays correctly

3. **Check Database**:
```sql
SELECT id, first_name, last_name, profile_image_url 
FROM public.fishermen 
WHERE profile_image_url IS NOT NULL;
```

## Troubleshooting

### Image Not Uploading
- Check Supabase Storage bucket exists and is public
- Verify storage policies are set correctly
- Check network connection
- Verify file size is under 5MB
- Check file format is supported (jpg, jpeg, png, webp)

### Image URL Not Saving
- Verify `profile_image_url` column exists in `fishermen` table
- Check RLS policies allow INSERT/UPDATE
- Verify the upload service returns a valid URL

### Image Not Displaying
- Verify the URL is accessible (public bucket)
- Check the URL format is correct
- Verify image file exists in storage

## Security Notes

1. **File Size Limit**: 5MB maximum
2. **File Type Validation**: Only image formats allowed
3. **Unique File Names**: Prevents overwriting
4. **Public Access**: Images are publicly accessible via URL
5. **RLS Policies**: Control who can upload/delete images

## Future Enhancements

- Image compression before upload
- Multiple image sizes (thumbnail, full size)
- Image cropping/editing before upload
- Delete old images when updating profile picture
- Image CDN integration for better performance


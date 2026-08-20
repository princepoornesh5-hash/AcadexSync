import crypto from 'crypto';
import { getImageKitClient } from './imagekit.client';
import { env } from '../config/env';
import {
  ALLOWED_MIME_TYPES,
  MIME_TO_EXTENSION_MAP,
  ImageKitAuthParams,
  StorageFileMetadata,
} from './imagekit.types';
import { ApiError } from '../utils/apiError';
import { Logger } from '../utils/logger';

export class ImageKitService {
  // =========================================================================
  // 1. DETERMINISTIC FOLDER BUILDERS
  // =========================================================================

  static generateFileId(): string {
    return crypto.randomBytes(16).toString('hex');
  }

  static buildNoteFolder(
    collegeId: string,
    courseId: string,
    semesterId: string,
    subjectId: string,
    noteId: string
  ): string {
    return `/acadex/colleges/${collegeId}/notes/courses/${courseId}/semesters/${semesterId}/subjects/${subjectId}/${noteId}`;
  }

  static buildProfileFolder(
    collegeId: string,
    role: string,
    entityId: string
  ): string {
    const cleanRole = role.toLowerCase().replace(/_/g, '-');
    return `/acadex/colleges/${collegeId}/profiles/${cleanRole}s/${entityId}`;
  }

  // =========================================================================
  // 2. MIME & EXTENSION VALIDATION
  // =========================================================================

  static validateMimeAndExtension(
    mimeType: string,
    fileName: string
  ): { valid: boolean; normalizedExtension: string; error?: string } {
    const cleanMime = mimeType.trim().toLowerCase();
    if (!ALLOWED_MIME_TYPES.includes(cleanMime as any)) {
      return {
        valid: false,
        normalizedExtension: '',
        error: `Unsupported MIME type "${cleanMime}". Allowed: PDF, DOC, DOCX, PPT, PPTX, JPG, PNG, WEBP`,
      };
    }

    const parts = fileName.trim().split('.');
    if (parts.length < 2) {
      return {
        valid: false,
        normalizedExtension: '',
        error: 'File name must have a valid extension',
      };
    }

    const ext = parts.pop()!.toLowerCase();
    const expectedExt = MIME_TO_EXTENSION_MAP[cleanMime];

    // Check if extension matches MIME category
    if (cleanMime === 'image/jpeg' && (ext === 'jpg' || ext === 'jpeg')) {
      return { valid: true, normalizedExtension: ext };
    }
    if (expectedExt && ext === expectedExt) {
      return { valid: true, normalizedExtension: ext };
    }

    return {
      valid: false,
      normalizedExtension: '',
      error: `File extension ".${ext}" does not match declared MIME type "${cleanMime}"`,
    };
  }

  // =========================================================================
  // 3. AUTHENTICATION PARAMETERS FOR UPLOAD
  // =========================================================================

  static getAuthenticationParameters(
    folder: string,
    fileName: string,
    maxSizeBytes: number = env.NOTES_MAX_FILE_SIZE_MB * 1024 * 1024,
    expiresInSeconds: number = env.SIGNED_URL_EXPIRY_SECONDS
  ): ImageKitAuthParams {
    try {
      const client = getImageKitClient();
      const token = this.generateFileId();
      const expire = Math.floor(Date.now() / 1000) + expiresInSeconds;
      const auth = client.getAuthenticationParameters(token, expire);

      return {
        token: auth.token,
        expire: auth.expire,
        signature: auth.signature,
        publicKey: env.IMAGEKIT_PUBLIC_KEY,
        urlEndpoint: env.IMAGEKIT_URL_ENDPOINT,
        folder,
        fileName,
        fileId: this.generateFileId(),
        expiresInSeconds,
        maxSizeBytes,
      };
    } catch (err: any) {
      Logger.error('Failed to generate ImageKit upload authentication parameters', err);
      throw ApiError.internal('Failed to initialize secure storage upload session');
    }
  }

  // =========================================================================
  // 4. DIRECT UPLOAD (SERVER-SIDE OR TEST)
  // =========================================================================

  static async uploadFile(options: {
    file: string | Buffer;
    fileName: string;
    folder: string;
    tags?: string[];
    useUniqueFileName?: boolean;
  }): Promise<StorageFileMetadata> {
    try {
      const client = getImageKitClient();
      const response = await client.upload({
        file: options.file,
        fileName: options.fileName,
        folder: options.folder,
        tags: options.tags || [],
        useUniqueFileName: options.useUniqueFileName ?? false,
      });

      return {
        fileId: response.fileId,
        name: response.name,
        size: response.size,
        filePath: response.filePath,
        url: response.url,
        thumbnailUrl: response.thumbnailUrl,
        fileType: response.fileType,
        mimeType: (response as any).mime || 'application/octet-stream',
      };
    } catch (err: any) {
      Logger.error(`Failed to upload file ${options.fileName} to ImageKit`, err);
      throw ApiError.internal('Storage service upload error');
    }
  }

  // =========================================================================
  // 5. FILE DETAILS & EXISTENCE VERIFICATION
  // =========================================================================

  static async getFileDetails(fileId: string): Promise<StorageFileMetadata | null> {
    try {
      const client = getImageKitClient();
      const response = await client.getFileDetails(fileId);
      if (!response) return null;

      return {
        fileId: response.fileId,
        name: response.name,
        size: response.size,
        filePath: response.filePath,
        url: response.url,
        thumbnailUrl: response.thumbnail || (response as any).thumbnailUrl,
        fileType: response.fileType,
        mimeType: (response as any).mime || 'application/octet-stream',
        createdAt: response.createdAt ? new Date(response.createdAt) : undefined,
        updatedAt: response.updatedAt ? new Date(response.updatedAt) : undefined,
      };
    } catch (err: any) {
      if (
        err.message?.includes('not found') ||
        err.help?.includes('not found') ||
        err.$metadata?.httpStatusCode === 404 ||
        err.status === 404
      ) {
        return null;
      }
      Logger.error(`Error verifying file details for ${fileId} in ImageKit`, err);
      return null;
    }
  }

  // =========================================================================
  // 6. SECURE SIGNED URL GENERATION
  // =========================================================================

  static generateSignedUrl(
    filePathOrUrl: string,
    expiresInSeconds: number = env.SIGNED_URL_EXPIRY_SECONDS
  ): string {
    try {
      const client = getImageKitClient();
      if (filePathOrUrl.startsWith('http')) {
        return client.url({
          src: filePathOrUrl,
          signed: true,
          expireSeconds: expiresInSeconds,
        });
      } else {
        return client.url({
          path: filePathOrUrl.startsWith('/') ? filePathOrUrl : `/${filePathOrUrl}`,
          signed: true,
          expireSeconds: expiresInSeconds,
        });
      }
    } catch (err: any) {
      Logger.error(`Failed to generate signed ImageKit URL for ${filePathOrUrl}`, err);
      throw ApiError.internal('Failed to generate secure download link');
    }
  }

  // =========================================================================
  // 7. FILE DELETION
  // =========================================================================

  static async deleteFile(fileId: string): Promise<boolean> {
    try {
      const client = getImageKitClient();
      await client.deleteFile(fileId);
      return true;
    } catch (err: any) {
      Logger.error(`Failed to delete file ${fileId} from ImageKit`, err);
      throw ApiError.internal('Storage service deletion error');
    }
  }
}

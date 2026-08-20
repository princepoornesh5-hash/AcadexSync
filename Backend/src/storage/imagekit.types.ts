export interface ImageKitConfig {
  publicKey: string;
  privateKey: string;
  urlEndpoint: string;
}

export interface ImageKitAuthParams {
  token: string;
  expire: number;
  signature: string;
  publicKey: string;
  urlEndpoint: string;
  folder: string;
  fileName: string;
  fileId: string;
  expiresInSeconds: number;
  maxSizeBytes: number;
}

export interface StorageFileMetadata {
  fileId: string;
  name: string;
  size: number;
  filePath: string;
  url: string;
  thumbnailUrl?: string;
  fileType: string;
  mimeType: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface SecureDownloadResult {
  downloadUrl: string;
  expiresInSeconds: number;
  fileName: string;
  mimeType: string;
  fileSize: number;
}

export const ALLOWED_DOC_MIME_TYPES = [
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-powerpoint',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
] as const;

export const ALLOWED_IMAGE_MIME_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
] as const;

export const ALLOWED_MIME_TYPES = [
  ...ALLOWED_DOC_MIME_TYPES,
  ...ALLOWED_IMAGE_MIME_TYPES,
] as const;

export const MIME_TO_EXTENSION_MAP: Record<string, string> = {
  'application/pdf': 'pdf',
  'application/msword': 'doc',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'docx',
  'application/vnd.ms-powerpoint': 'ppt',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation': 'pptx',
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};

export const EXTENSION_TO_MIME_MAP: Record<string, string> = {
  pdf: 'application/pdf',
  doc: 'application/msword',
  docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ppt: 'application/vnd.ms-powerpoint',
  pptx: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  png: 'image/png',
  webp: 'image/webp',
};

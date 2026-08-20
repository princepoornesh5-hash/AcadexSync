import { ImageKitService } from '../../src/storage/imagekit.service';
import { setImageKitClientForTesting } from '../../src/storage/imagekit.client';

describe('ACADEX Phase 9L.2 — ImageKit Storage Unit Tests', () => {
  afterEach(() => {
    setImageKitClientForTesting(null);
    jest.restoreAllMocks();
  });

  describe('1. MIME & Extension Validation', () => {
    it('should validate and normalize supported PDF document', () => {
      const result = ImageKitService.validateMimeAndExtension('application/pdf', 'lecture_notes_ch1.pdf');
      expect(result.valid).toBe(true);
      expect(result.normalizedExtension).toBe('pdf');
      expect(result.error).toBeUndefined();
    });

    it('should validate and normalize supported Word (.docx) document', () => {
      const result = ImageKitService.validateMimeAndExtension(
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'assignment_1.docx'
      );
      expect(result.valid).toBe(true);
      expect(result.normalizedExtension).toBe('docx');
    });

    it('should validate and normalize supported PowerPoint (.pptx) document', () => {
      const result = ImageKitService.validateMimeAndExtension(
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'slides.pptx'
      );
      expect(result.valid).toBe(true);
      expect(result.normalizedExtension).toBe('pptx');
    });

    it('should validate and normalize supported JPEG, PNG, and WebP images', () => {
      const resJpg = ImageKitService.validateMimeAndExtension('image/jpeg', 'diagram.jpg');
      expect(resJpg.valid).toBe(true);
      expect(resJpg.normalizedExtension).toBe('jpg');

      const resPng = ImageKitService.validateMimeAndExtension('image/png', 'chart.png');
      expect(resPng.valid).toBe(true);
      expect(resPng.normalizedExtension).toBe('png');

      const resWebp = ImageKitService.validateMimeAndExtension('image/webp', 'avatar.webp');
      expect(resWebp.valid).toBe(true);
      expect(resWebp.normalizedExtension).toBe('webp');
    });

    it('should reject unsupported MIME type (e.g. video/mp4, application/zip)', () => {
      const resVideo = ImageKitService.validateMimeAndExtension('video/mp4', 'recording.mp4');
      expect(resVideo.valid).toBe(false);
      expect(resVideo.error).toContain('Unsupported MIME type');

      const resZip = ImageKitService.validateMimeAndExtension('application/zip', 'archive.zip');
      expect(resZip.valid).toBe(false);
      expect(resZip.error).toContain('Unsupported MIME type');
    });

    it('should reject mismatched MIME and extension', () => {
      const resMismatch = ImageKitService.validateMimeAndExtension('application/pdf', 'malicious.exe');
      expect(resMismatch.valid).toBe(false);
      expect(resMismatch.error).toContain('does not match');
    });
  });

  describe('2. Deterministic Folder Path Builders', () => {
    it('should construct secure, tenant-isolated Note folder path', () => {
      const folder = ImageKitService.buildNoteFolder('col123', 'course456', 'sem789', 'sub101', 'note999');
      expect(folder).toBe('/acadex/colleges/col123/notes/courses/course456/semesters/sem789/subjects/sub101/note999');
    });

    it('should construct secure, tenant-isolated Profile picture folder path', () => {
      const folder = ImageKitService.buildProfileFolder('col123', 'STUDENT', 'stu456');
      expect(folder).toBe('/acadex/colleges/col123/profiles/students/stu456');
    });
  });

  describe('3. ImageKit Client Operations (Mocked)', () => {
    it('should generate authentication parameters for client-side upload', () => {
      const mockClient = {
        getAuthenticationParameters: jest.fn().mockReturnValue({
          token: 'mock-token-123',
          expire: 1700000000,
          signature: 'mock-signature-abc',
        }),
      } as any;

      setImageKitClientForTesting(mockClient);

      const auth = ImageKitService.getAuthenticationParameters('/notes/test', 'file.pdf');
      expect(auth.token).toBe('mock-token-123');
      expect(auth.signature).toBe('mock-signature-abc');
      expect(auth.folder).toBe('/notes/test');
      expect(auth.fileName).toBe('file.pdf');
    });

    it('should retrieve file details via getFileDetails', async () => {
      const mockClient = {
        getFileDetails: jest.fn().mockResolvedValue({
          fileId: 'ik_file_123',
          name: 'notes.pdf',
          size: 1024 * 50,
          filePath: '/notes/test/notes.pdf',
          url: 'https://ik.imagekit.io/mock/notes.pdf',
          thumbnailUrl: 'https://ik.imagekit.io/mock/tr:w-300/notes.pdf',
          fileType: 'non-image',
          mime: 'application/pdf',
          createdAt: new Date().toISOString(),
        }),
      } as any;

      setImageKitClientForTesting(mockClient);

      const details = await ImageKitService.getFileDetails('ik_file_123');
      expect(details).not.toBeNull();
      expect(details?.fileId).toBe('ik_file_123');
      expect(details?.size).toBe(1024 * 50);
      expect(details?.url).toContain('ik.imagekit.io');
    });

    it('should return null when getFileDetails throws not found error', async () => {
      const notFoundErr = new Error('The requested file does not exist');
      const mockClient = {
        getFileDetails: jest.fn().mockRejectedValue(notFoundErr),
      } as any;

      setImageKitClientForTesting(mockClient);

      const details = await ImageKitService.getFileDetails('non_existent_file');
      expect(details).toBeNull();
    });

    it('should generate signed URL with expiration', () => {
      const mockClient = {
        url: jest.fn().mockReturnValue('https://ik.imagekit.io/mock/notes.pdf?ik-s=signed123'),
      } as any;

      setImageKitClientForTesting(mockClient);

      const signedUrl = ImageKitService.generateSignedUrl('/notes/notes.pdf', 300);
      expect(signedUrl).toContain('ik-s=signed123');
      expect(mockClient.url).toHaveBeenCalledWith({
        path: '/notes/notes.pdf',
        signed: true,
        expireSeconds: 300,
      });
    });

    it('should delete file via deleteFile', async () => {
      const mockClient = {
        deleteFile: jest.fn().mockResolvedValue({}),
      } as any;

      setImageKitClientForTesting(mockClient);

      const deleted = await ImageKitService.deleteFile('ik_file_123');
      expect(deleted).toBe(true);
      expect(mockClient.deleteFile).toHaveBeenCalledWith('ik_file_123');
    });
  });
});

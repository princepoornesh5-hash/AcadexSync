import { FcmService } from '../../src/services/fcm.service';

describe('ACADEX Phase 9M.1 — FCM Service Unit Tests', () => {
  afterEach(() => {
    FcmService.setMockMessagingForTesting(null);
  });

  it('should return empty stats for empty token array', async () => {
    const result = await FcmService.sendMulticast([], {
      title: 'Test',
      body: 'Message',
    });
    expect(result.successfulCount).toBe(0);
    expect(result.failureCount).toBe(0);
    expect(result.invalidTokens).toEqual([]);
  });

  it('should use injected mock client in test environment and return success counts', async () => {
    const mockClient = {
      sendMulticast: jest.fn().mockResolvedValue({
        successfulCount: 2,
        failureCount: 0,
        invalidTokens: [],
      }),
    };

    FcmService.setMockMessagingForTesting(mockClient);

    const result = await FcmService.sendMulticast(['token_1', 'token_2'], {
      title: 'Study Note Ready',
      body: 'Chapter 1 Notes have been uploaded',
      data: { noteId: 'note_123' },
    });

    expect(mockClient.sendMulticast).toHaveBeenCalledWith(
      ['token_1', 'token_2'],
      expect.objectContaining({
        title: 'Study Note Ready',
        body: 'Chapter 1 Notes have been uploaded',
      })
    );
    expect(result.successfulCount).toBe(2);
    expect(result.failureCount).toBe(0);
    expect(result.invalidTokens).toEqual([]);
  });

  it('should correctly capture invalid and unregistered tokens for automatic cleanup', async () => {
    const mockClient = {
      sendMulticast: jest.fn().mockResolvedValue({
        successfulCount: 1,
        failureCount: 1,
        invalidTokens: ['invalid_expired_token'],
      }),
    };

    FcmService.setMockMessagingForTesting(mockClient);

    const result = await FcmService.sendMulticast(
      ['valid_token', 'invalid_expired_token'],
      {
        title: 'Timetable Published',
        body: 'New timetable is available',
      }
    );

    expect(result.successfulCount).toBe(1);
    expect(result.failureCount).toBe(1);
    expect(result.invalidTokens).toContain('invalid_expired_token');
  });
});

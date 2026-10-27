import { z } from 'zod';

export const chatMessageSchema = z.object({
  role: z.enum(['user', 'assistant', 'model'], {
    errorMap: () => ({ message: "Role must be 'user', 'assistant', or 'model'" }),
  }),
  content: z
    .string({ required_error: 'Message content is required' })
    .trim()
    .min(1, 'Message content cannot be empty')
    .max(2000, 'Individual message content cannot exceed 2000 characters'),
});

export const chatRequestSchema = z.object({
  message: z
    .string({ required_error: 'Message is required' })
    .trim()
    .min(1, 'Message cannot be empty')
    .max(2000, 'Message cannot exceed 2000 characters'),
  history: z
    .array(chatMessageSchema)
    .max(10, 'Conversation history cannot exceed 10 turns')
    .optional(),
});

export type ChatMessage = z.infer<typeof chatMessageSchema>;
export type ChatRequestInput = z.infer<typeof chatRequestSchema>;

export const confirmActionSchema = z.object({
  actionId: z.string({ required_error: 'actionId is required' }).trim().min(1, 'actionId cannot be empty'),
  idempotencyKey: z.string().trim().optional(),
});

export const cancelActionSchema = z.object({
  actionId: z.string({ required_error: 'actionId is required' }).trim().min(1, 'actionId cannot be empty'),
});

export type ConfirmActionInput = z.infer<typeof confirmActionSchema>;
export type CancelActionInput = z.infer<typeof cancelActionSchema>;

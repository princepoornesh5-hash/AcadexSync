import ImageKit from 'imagekit';
import { env } from '../config/env';

let imageKitInstance: ImageKit | null = null;

export function getImageKitClient(): ImageKit {
  if (!imageKitInstance) {
    imageKitInstance = new ImageKit({
      publicKey: env.IMAGEKIT_PUBLIC_KEY,
      privateKey: env.IMAGEKIT_PRIVATE_KEY,
      urlEndpoint: env.IMAGEKIT_URL_ENDPOINT,
    });
  }
  return imageKitInstance;
}

export function setImageKitClientForTesting(client: ImageKit | null): void {
  imageKitInstance = client;
}

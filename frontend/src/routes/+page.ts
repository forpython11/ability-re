import { getHomePage } from '$lib/api/client';
import { fallbackHomePage } from '$lib/site/fallback';

export const ssr = false;

export async function load() {
  try {
    return {
      home: await getHomePage(),
      apiAvailable: true,
    };
  } catch {
    return {
      home: fallbackHomePage,
      apiAvailable: false,
    };
  }
}

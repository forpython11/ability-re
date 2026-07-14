import { getHomePage } from '$lib/api/server';
import { fallbackHomePage } from '$lib/site/fallback';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch }) => {
  try {
    return {
      home: await getHomePage(fetch),
      apiAvailable: true,
    };
  } catch {
    return {
      home: fallbackHomePage,
      apiAvailable: false,
    };
  }
};

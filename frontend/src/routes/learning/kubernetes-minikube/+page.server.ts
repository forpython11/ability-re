import { getLearningRecord } from '$lib/api/server';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch }) => {
  const slug = 'kubernetes-minikube';

  try {
    return {
      record: await getLearningRecord(fetch, slug),
      apiAvailable: true,
    };
  } catch {
    return {
      record: null,
      apiAvailable: false,
    };
  }
};

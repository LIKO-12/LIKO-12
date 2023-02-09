import { loveEvents } from 'core/love-events';

/**
 * A function that returns true when it has been completed.
 */
type AsyncJob = () => boolean;

const jobs: (AsyncJob | undefined)[] = [];
let lastJobId = -1, lastActiveJobId = -1;

export function addJob(job: AsyncJob): void {
    let i = 0;
    while (jobs[i] !== undefined) i++;

    jobs[i] = job;

    if (i > lastJobId) lastJobId = i;
    if (i > lastActiveJobId) lastActiveJobId = i;
}

let deferredError: unknown = undefined;
let deferredErrorSet = false;

/**
 * Throws an error globally at the next update iteration.
 * 
 * This was needed to throw errors out of the async context.
 * Otherwise the promise would catch the error and prevent it from escaping.
 * 
 * And thus result with a promise in an uncaught error state.
 */
export function deferError(this: unknown, err: unknown) {
    if (deferredErrorSet) return;
    deferredError = err, deferredErrorSet = true;
}

function processJobs() {
    for (let i = 0; i <= lastJobId; i++) {
        const job = jobs[i];
        if (job === undefined) continue;

        if (job()) jobs[i] = undefined;
        else if (i > lastActiveJobId) lastActiveJobId = i;
    }

    lastJobId = lastActiveJobId;
    if (deferredErrorSet) throw deferredError;
}

loveEvents.on('update', processJobs);

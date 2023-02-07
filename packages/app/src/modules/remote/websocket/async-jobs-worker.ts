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

function processJobs() {
    for (let i = 0; i <= lastJobId; i++) {
        const job = jobs[i];
        if (job === undefined) continue;

        if (job()) jobs[i] = undefined;
        else if (i > lastActiveJobId) lastActiveJobId = i;
    }

    lastJobId = lastActiveJobId;
}

loveEvents.on('update', processJobs);

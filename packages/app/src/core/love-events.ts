import EventsEmitter from "./events-emitter";

/**
 * A LÖVE Events Emitter.
 * This module acts as a singleton instance.
 */
const loveEvents = new EventsEmitter();

export default loveEvents;
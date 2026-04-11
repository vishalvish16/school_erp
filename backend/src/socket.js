/**
 * Socket.IO instance holder.
 * Initialized from server.js after httpServer is created.
 * Imported by controllers that need to emit events.
 */

let io = null;

export function setIO(ioInstance) {
  io = ioInstance;
}

export function getIO() {
  if (!io) {
    throw new Error('Socket.IO not initialized. Call setIO() first.');
  }
  return io;
}

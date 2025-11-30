// Module pour exposer l'instance Socket.IO aux routes Express
let ioInstance = null;

module.exports = {
  setIO: (io) => {
    ioInstance = io;
  },
  getIO: () => {
    return ioInstance;
  }
};




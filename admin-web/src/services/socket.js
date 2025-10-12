import { io } from 'socket.io-client';

const SOCKET_URL = 'http://localhost:8000';

class SocketService {
  constructor() {
    this.socket = null;
  }

  connect(token) {
    if (this.socket?.connected) {
      return;
    }

    this.socket = io(SOCKET_URL, {
      auth: { token },
      transports: ['websocket'],
    });

    this.socket.on('connect', () => {
      console.log('✅ Socket connecté (Admin)');
    });

    this.socket.on('disconnect', () => {
      console.log('❌ Socket déconnecté');
    });

    this.socket.on('connect_error', (error) => {
      console.error('Erreur de connexion socket:', error);
    });
  }

  disconnect() {
    if (this.socket?.connected) {
      this.socket.disconnect();
    }
  }

  // Listen to real-time events
  onNewRide(callback) {
    this.socket?.on('new_ride', callback);
  }

  onRideUpdate(callback) {
    this.socket?.on('ride_update', callback);
  }

  onDriverStatusChange(callback) {
    this.socket?.on('driver_status_change', callback);
  }

  onDriverLocationUpdate(callback) {
    this.socket?.on('driver_location', callback);
  }

  // Remove listeners
  off(event) {
    this.socket?.off(event);
  }
}

export default new SocketService();


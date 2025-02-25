import React, { useState, useEffect } from 'react';
import '../styles/App.css';
import Login from './login';
import Register from './register';
import Dashboard from './dashboard';
import { fetchNui } from '../utils/fetchNui';

export interface UserData {
  username: string;
  balance: number;
  bankBalance: number;
  cryptoValue: number;
}

const App: React.FC = () => {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [isRegistering, setIsRegistering] = useState(false);
  const [userData, setUserData] = useState<UserData | null>(null);

  const handleLogin = (data: UserData) => {
    console.log('Login successful, received userData:', data);
    setUserData(data);
    setIsLoggedIn(true);
  };

  const handleLogout = () => {
    setIsLoggedIn(false);
    setUserData(null);
    fetchNui('closeUI');
  };

  const handleRegisterRedirect = () => {
    setIsRegistering(true);
  };

  const handleLoginRedirect = () => {
    setIsRegistering(false);
  };

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        fetchNui('closeUI', {})
          .then(() => handleLogout())
          .catch(error => console.error('Error invoking NUI callback:', error));
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, []);

  return (
    <div className="app">
      {isLoggedIn ? (
        <Dashboard userData={userData} onLogout={handleLogout} onLoginRedirect={handleLoginRedirect} />
      ) : (
        isRegistering ? (
          <Register onLogin={handleLogin} onLoginRedirect={handleLoginRedirect} />
        ) : (
          <Login onLogin={handleLogin} onRegister={handleRegisterRedirect} />
        )
      )}
    </div>
  );
};

export default App;
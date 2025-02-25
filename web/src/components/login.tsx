import React, { useState, useEffect } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faCoins } from '@fortawesome/free-solid-svg-icons';
import { fetchNui } from '../utils/fetchNui';
import '../styles/App.css';
import { UserData } from './App';

interface LoginProps {
  onLogin: (data: UserData) => void;
  onRegister: () => void;
}

const Login: React.FC<LoginProps> = ({ onLogin, onRegister }) => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [errorMessage, setErrorMessage] = useState('');

  const handleLogin = () => {
    fetchNui('login', { username, password })
      .then((data: any) => {
        if (data.success) {
          onLogin(data.userData);
        } else {
          setErrorMessage('Login failed. Are you sure your credentials are valid? Check again.');
          setTimeout(() => setErrorMessage(''), 4000);
        }
      })
      .catch((error) => {
        console.error('Error logging in:', error);
        setErrorMessage('An error occurred while logging in. Please try again later.');
		setTimeout(() => setErrorMessage(''), 4000);
	  });
  };

  return (
    <div className="centered-container">
      <div className="card">
        <h2><FontAwesomeIcon icon={faCoins} /> vCoin Vault</h2>
        {errorMessage && <p className="error-message">{errorMessage}</p>}
        <input
          type="text"
          placeholder="Username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
        />
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
        <button className="login" onClick={handleLogin}>Login</button>
        <button className="register" onClick={onRegister}>Register</button>
      </div>
    </div>
  );
};

export default Login;

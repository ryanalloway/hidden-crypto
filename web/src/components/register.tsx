import React, { useState, useEffect } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faSignInAlt } from '@fortawesome/free-solid-svg-icons';
import { fetchNui } from '../utils/fetchNui';
import '../styles/App.css';

interface RegisterProps {
  onLogin: (data: any) => void;
  onLoginRedirect: () => void;
}

const Register: React.FC<RegisterProps> = ({ onLogin, onLoginRedirect }) => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [errorMessage, setErrorMessage] = useState('');

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        fetchNui('closeUI', {})
          .then(() => onLoginRedirect())
          .catch(error => console.error('Error invoking NUI callback:', error));
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [onLoginRedirect]);

  const handleRegister = async () => {
    // Validate input fields
    if (!username || !password) {
      setErrorMessage('Username and password cannot be empty.');
      setTimeout(() => setErrorMessage(''), 4000);
      return;
    }

    try {
      const data = await fetchNui('register', { username, password });
      if (data.success) {
        onLogin(data.userData);
      } else {
        if (data.error === 'Username taken') {
          setErrorMessage('This account name is already taken, please use another.');
		  setTimeout(() => setErrorMessage(''), 4000);
        } else {
          setErrorMessage('Registration failed. Please try again.');
          setTimeout(() => setErrorMessage(''), 4000);
        }
      }
    } catch (error) {
      console.error('Error during registration:', error);
      setErrorMessage('An error occurred during registration. Please try again.');
      setTimeout(() => setErrorMessage(''), 4000);
    }
  };

  return (
    <div className="centered-container">
      <div className="card">
        <h2><FontAwesomeIcon icon={faSignInAlt} /> Register</h2>
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
        <button className="register" onClick={handleRegister}>Register</button>
        <button className="have-account" onClick={onLoginRedirect}>Have an Account? Login</button>
      </div>
    </div>
  );
};

export default Register;